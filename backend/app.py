import os
import platform
from flask import Flask, jsonify, render_template

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/health")
def health():
    return jsonify(
        {
            "status": "ok",
            "service": "aws-devops-demo",
            "version": "1.0.0",
            "hostname": platform.node(),
        }
    )


@app.route("/api/metrics")
def metrics():
    return jsonify(
        {
            "uptime_seconds": 0,
            "requests_total": 0,
            "status": "healthy",
            "environment": os.getenv("APP_ENV", "development"),
        }
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port, debug=False)
