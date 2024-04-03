import time
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
        requests.post(url=f"{url}/", json=PAYLOAD).raise_for_status()
        print(f"POST {PAYLOAD} to {url}")
        sleep_time = random.randint(1, 10)
        print(f"Sleeping for {sleep_time} seconds")
        time.sleep(sleep_time)


main()