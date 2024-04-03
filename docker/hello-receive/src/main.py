import os
from flask import Flask, request, render_template
from flask_socketio import SocketIO
from datetime import datetime, timezone

app = Flask(__name__)
socket = SocketIO(app=app)

@app.route("/post", methods=["POST"])
def handle_post() -> None:
    try:
        message = request.get_json()["message"]
        timestamp = datetime.now(timezone.utc)
    except Exception as exc:
        print(f"Failed to parse request: {request.data} with error {exc}")
        return

    socket.emit("new_request", f"{timestamp}: {message}")
    result = f"Recieved message {message} at {timestamp}"
    print(result)
    
    return result

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    socket.run(app=app, host="0.0.0.0", port=os.environ.get("PORT", 8080), allow_unsafe_werkzeug=True)