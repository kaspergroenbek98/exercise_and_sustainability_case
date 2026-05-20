# Google Health → Snowflake loader

Pulls daily activity (calories, steps, distance, active zone minutes) from Google
Health API v4 and MERGEs into `RAW.GOOGLE_HEALTH.DAILY_ACTIVITY`. Runs daily on
Windows Task Scheduler; production would lift to a Snowflake Task with External
Network Access.

## One-time setup

### 1. Google Cloud project

1. Go to https://console.cloud.google.com
2. New project → name it anything (e.g. `personal-health-loader`)
3. APIs & Services → Library → enable **Health API**
4. APIs & Services → OAuth consent screen → External → fill the minimum (app name + your email). Don't publish; keep in Testing.
5. APIs & Services → Credentials → Create credentials → OAuth client ID → Desktop app. Download the JSON; save it as `client_secret.json` next to this README.

### 2. Fitbit linkage

The Fitbit account must be linked to the same Google account whose OAuth client
you just created. Open the Fitbit app → Settings → Google connection → link.

### 3. Snowflake target table

Run this once (as DBT role on RAW database):

```sql
use role dbt;
use database raw;
use warehouse analytics_wh;

create schema if not exists google_health
    comment = 'Personal daily activity from Google Health API v4.';

use schema google_health;

create table if not exists daily_activity (
    activity_date          date,
    source_family          varchar,
    calories_burned_kcal   float,
    steps                  integer,
    distance_meters        float,
    active_zone_minutes    integer,
    ingested_at            timestamp_ntz default current_timestamp(),
    primary key (activity_date, source_family)
);
```

### 4. Python env

```bash
cd loaders/google_health
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your Snowflake connection details
```

## OAuth bootstrap

Run once to get a refresh token.

```bash
python auth_start.py            # Prints a consent URL
# Open the URL in a browser, sign in, allow scopes, copy the code from the redirect
python auth_exchange.py <code>  # Exchanges the code for a refresh token, writes to .env
```

## Daily run

```bash
python load_daily_activity.py
```

By default loads the last 3 days (idempotent MERGE on `(activity_date, source_family)`).

Backfill: `python load_daily_activity.py --start 2024-01-01 --end 2024-12-31`.

## Schedule

Windows Task Scheduler → Create Basic Task → Daily → 06:00 →
`C:\path\to\.venv\Scripts\python.exe` with argument
`C:\path\to\load_daily_activity.py`.

## With more time

- Move to a Snowflake Task + External Network Access for the schedule. Removes
  the laptop dependency.
- Add a `raw_events` VARIANT table next to `daily_activity` so API shape changes
  (Google Health is still on v4 and evolves) are captured for diagnosis.
- Multi-user: add `user_id` to the table + the OAuth flow per user. Documented
  in [`docs/04-trade-offs.md`](../../docs/04-trade-offs.md).
