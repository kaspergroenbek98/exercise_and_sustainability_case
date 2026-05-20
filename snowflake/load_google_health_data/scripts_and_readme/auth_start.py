"""Print the Google OAuth consent URL for the Health API. Run once, before auth_exchange.py.

Reads client_secret.json (downloaded from Google Cloud Console) and prints a URL.
Open the URL in a browser, allow the scopes, and copy the `code=...` parameter
from the redirect URL. Feed that code to auth_exchange.py.
"""

import json
import urllib.parse
from pathlib import Path

CLIENT_SECRET_PATH = Path(__file__).parent / "client_secret.json"
SCOPES = [
    "https://www.googleapis.com/auth/fitness.activity.read",
]
REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob"  # out-of-band — code shown in browser after consent


def main() -> None:
    if not CLIENT_SECRET_PATH.exists():
        raise SystemExit(
            f"Missing {CLIENT_SECRET_PATH}. Download the OAuth client JSON from Google Cloud Console."
        )

    with CLIENT_SECRET_PATH.open() as f:
        client = json.load(f)["installed"]

    params = {
        "client_id": client["client_id"],
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": " ".join(SCOPES),
        "access_type": "offline",
        "prompt": "consent",  # forces a refresh token even after first consent
    }

    url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(params)
    print("\nOpen this URL in a browser, allow the scopes, then copy the code shown in the page or URL:\n")
    print(url)
    print("\nThen run: python auth_exchange.py <code>\n")


if __name__ == "__main__":
    main()
