# Python 3 server example
import os
from flask import Flask, request
from datetime import datetime, timezone

app = Flask(__name__)

messages = []

@app.route("/", methods=["POST"])
def handle_post() -> None:
    try:
        message = request.get_json()["message"]
        timestamp = datetime.now(timezone.utc)
    except Exception as exc:
        print(f"Failed to parse request: {request.data} with error {exc}")
        return

    messages.append({"timestamp": timestamp, "message": message})
    result = f"Recieved message {message} at {timestamp}"
    print(result)
    return result


@app.route("/", methods=["GET"])
def handle_get() -> None:
    return "\n".join(str(message["timestamp"]) + ": " + message["message"] for message in messages)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=os.environ.get("PORT", 8080), debug=True)
