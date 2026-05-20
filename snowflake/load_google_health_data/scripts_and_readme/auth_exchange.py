"""Exchange a Google OAuth code for a refresh token. Writes the refresh token + client
ID/secret into .env so load_daily_activity.py can mint short-lived access tokens.

Run after auth_start.py:
    python auth_exchange.py <code>
"""

import json
import sys
from pathlib import Path

import requests

CLIENT_SECRET_PATH = Path(__file__).parent / "client_secret.json"
ENV_PATH          = Path(__file__).parent / ".env"
REDIRECT_URI      = "urn:ietf:wg:oauth:2.0:oob"


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python auth_exchange.py <code>")
    code = sys.argv[1]

    with CLIENT_SECRET_PATH.open() as f:
        client = json.load(f)["installed"]

    resp = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "code":           code,
            "client_id":      client["client_id"],
            "client_secret":  client["client_secret"],
            "redirect_uri":   REDIRECT_URI,
            "grant_type":     "authorization_code",
        },
        timeout=30,
    )
    resp.raise_for_status()
    tokens = resp.json()

    if "refresh_token" not in tokens:
        raise SystemExit(
            "No refresh_token returned. Re-run auth_start.py and ensure the URL has prompt=consent."
        )

    # Write client_id, client_secret, refresh_token into .env (preserve other lines).
    env_lines = []
    if ENV_PATH.exists():
        env_lines = ENV_PATH.read_text().splitlines()

    updates = {
        "GOOGLE_CLIENT_ID":     client["client_id"],
        "GOOGLE_CLIENT_SECRET": client["client_secret"],
        "GOOGLE_REFRESH_TOKEN": tokens["refresh_token"],
    }

    seen = set()
    new_lines = []
    for line in env_lines:
        key = line.split("=", 1)[0] if "=" in line else None
        if key in updates:
            new_lines.append(f"{key}={updates[key]}")
            seen.add(key)
        else:
            new_lines.append(line)
    for key, value in updates.items():
        if key not in seen:
            new_lines.append(f"{key}={value}")

    ENV_PATH.write_text("\n".join(new_lines) + "\n")
    print(f"Wrote refresh token to {ENV_PATH}. You can now run load_daily_activity.py.")


if __name__ == "__main__":
    main()
