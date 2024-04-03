import time
from urllib.error import HTTPError
import requests
import os
import sys
import random


PAYLOAD = {"message": "Hello world"}


def main() -> None:
    try:
        url = os.environ["SERVER_URL"]
    except KeyError as exc:
        print(f"Missing environment variable: {exc}")
        sys.exit(1)
    
    while True:
        try:
            requests.post(url=f"{url}/post", json=PAYLOAD).raise_for_status()
            print(f"POST {PAYLOAD} to {url}/post", end="...")

            # Store liveness check
            with open("/liveness", mode="w", encoding="utf-8") as f:
                f.write(str(PAYLOAD))
        except HTTPError as exc:
            print(f"Bad response from server: {exc}", end="...")
        except requests.exceptions.ConnectionError as exc:
            print(f"Unable to connect to {url}, is the server up?", end="...")
        sleep_time = random.randint(1, 10)
        print(f"sleeping for {sleep_time} seconds")
        time.sleep(sleep_time)

        # Reset liveness check
        try:
            os.remove("/liveness")
        except OSError:
            pass


main()