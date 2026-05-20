"""Daily Google Health → Snowflake loader.

Calls the Google Health API v4 `:rollUp` endpoint for the configured Fitbit
device family, aggregates to one row per (activity_date, source_family), and
MERGEs into RAW.GOOGLE_HEALTH.DAILY_ACTIVITY.

Default behaviour: pull the last 3 days (rolling backfill, idempotent).
Backfill mode: pass --start YYYY-MM-DD --end YYYY-MM-DD.

The 3-day rolling window covers late-arriving syncs from the Fitbit app without
re-pulling the whole history daily. The MERGE on the natural key makes that safe.
"""

from __future__ import annotations

import argparse
import os
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

import requests
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

LOCAL_TZ = ZoneInfo("Europe/Copenhagen")

GOOGLE_OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_ROLLUP_URL      = "https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate"

# Data type IDs from Google Health / Fit
DATA_TYPES = {
    "calories":          {"dataTypeName": "com.google.calories.expended"},
    "steps":             {"dataTypeName": "com.google.step_count.delta"},
    "distance":          {"dataTypeName": "com.google.distance.delta"},
    "active_minutes":    {"dataTypeName": "com.google.active_minutes"},
}


def mint_access_token() -> str:
    """Trade the refresh token for a short-lived access token."""
    resp = requests.post(
        GOOGLE_OAUTH_TOKEN_URL,
        data={
            "client_id":     os.environ["GOOGLE_CLIENT_ID"],
            "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
            "refresh_token": os.environ["GOOGLE_REFRESH_TOKEN"],
            "grant_type":    "refresh_token",
        },
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def day_bounds_ms(d: date) -> tuple[int, int]:
    """Local-midnight-to-midnight in epoch milliseconds, for the rollUp request."""
    start = datetime.combine(d,                          time.min, tzinfo=LOCAL_TZ)
    end   = datetime.combine(d + timedelta(days=1),      time.min, tzinfo=LOCAL_TZ)
    return int(start.timestamp() * 1000), int(end.timestamp() * 1000)


def fetch_day(access_token: str, d: date) -> dict:
    """One day, all four data types, in one rollUp call."""
    start_ms, end_ms = day_bounds_ms(d)
    body = {
        "aggregateBy":           list(DATA_TYPES.values()),
        "bucketByTime":          {"durationMillis": end_ms - start_ms},
        "startTimeMillis":       start_ms,
        "endTimeMillis":         end_ms,
    }
    resp = requests.post(
        GOOGLE_ROLLUP_URL,
        headers={"Authorization": f"Bearer {access_token}"},
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def extract_metrics(payload: dict) -> dict[str, float]:
    """Pull the four numbers out of the rollUp response. Returns {} for an empty day."""
    metrics = {"calories_burned_kcal": None, "steps": None, "distance_meters": None, "active_zone_minutes": None}

    for bucket in payload.get("bucket", []):
        for dataset in bucket.get("dataset", []):
            type_name = dataset.get("dataSourceId", "")
            points    = dataset.get("point", [])
            if not points:
                continue
            value = points[0].get("value", [{}])[0]

            if "calories" in type_name:
                metrics["calories_burned_kcal"] = round(value.get("fpVal", 0.0), 1)
            elif "step_count" in type_name:
                metrics["steps"] = int(value.get("intVal", 0))
            elif "distance" in type_name:
                metrics["distance_meters"] = round(value.get("fpVal", 0.0), 1)
            elif "active_minutes" in type_name:
                metrics["active_zone_minutes"] = int(value.get("intVal", 0))

    return metrics


def merge_rows(conn, source_family: str, rows: list[tuple]) -> int:
    """MERGE into RAW.GOOGLE_HEALTH.DAILY_ACTIVITY on (activity_date, source_family)."""
    if not rows:
        return 0

    cur = conn.cursor()
    cur.execute("create or replace temporary table _stage_daily_activity like raw.google_health.daily_activity;")
    cur.executemany(
        """insert into _stage_daily_activity
               (activity_date, source_family, calories_burned_kcal, steps, distance_meters, active_zone_minutes)
           values (%s, %s, %s, %s, %s, %s)""",
        rows,
    )

    cur.execute(
        """merge into raw.google_health.daily_activity tgt
           using _stage_daily_activity src
              on tgt.activity_date  = src.activity_date
             and tgt.source_family  = src.source_family
           when matched then update set
                 calories_burned_kcal = src.calories_burned_kcal,
                 steps                = src.steps,
                 distance_meters      = src.distance_meters,
                 active_zone_minutes  = src.active_zone_minutes,
                 ingested_at          = current_timestamp()
           when not matched then insert
             (activity_date, source_family, calories_burned_kcal, steps, distance_meters, active_zone_minutes)
             values (src.activity_date, src.source_family, src.calories_burned_kcal, src.steps, src.distance_meters, src.active_zone_minutes);"""
    )
    return cur.rowcount or 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start", type=lambda s: datetime.strptime(s, "%Y-%m-%d").date(), help="Backfill start date (YYYY-MM-DD).")
    parser.add_argument("--end",   type=lambda s: datetime.strptime(s, "%Y-%m-%d").date(), help="Backfill end date inclusive (YYYY-MM-DD).")
    parser.add_argument("--lookback-days", type=int, default=3, help="Default daily window. Ignored when --start/--end supplied.")
    return parser.parse_args()


def main() -> None:
    args   = parse_args()
    today  = datetime.now(LOCAL_TZ).date()

    if args.start and args.end:
        days = [args.start + timedelta(days=n) for n in range((args.end - args.start).days + 1)]
    else:
        days = [today - timedelta(days=n) for n in range(args.lookback_days, 0, -1)]

    print(f"Loading {len(days)} days from {days[0]} to {days[-1]}")

    access_token = mint_access_token()
    source       = os.environ.get("SOURCE_FAMILY", "google-wearables-fitbit")

    rows = []
    for d in days:
        m = extract_metrics(fetch_day(access_token, d))
        rows.append((d, source, m["calories_burned_kcal"], m["steps"], m["distance_meters"], m["active_zone_minutes"]))
        print(f"  {d}: kcal={m['calories_burned_kcal']}, steps={m['steps']}, distance_m={m['distance_meters']}, azm={m['active_zone_minutes']}")

    conn = snowflake.connector.connect(
        account   = os.environ["SNOWFLAKE_ACCOUNT"],
        user      = os.environ["SNOWFLAKE_USER"],
        password  = os.environ["SNOWFLAKE_PASSWORD"],
        role      = os.environ["SNOWFLAKE_ROLE"],
        warehouse = os.environ["SNOWFLAKE_WAREHOUSE"],
        database  = os.environ["SNOWFLAKE_DATABASE"],
        schema    = os.environ["SNOWFLAKE_SCHEMA"],
    )
    try:
        count = merge_rows(conn, source, rows)
        print(f"MERGEd {count} rows into RAW.GOOGLE_HEALTH.DAILY_ACTIVITY")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
