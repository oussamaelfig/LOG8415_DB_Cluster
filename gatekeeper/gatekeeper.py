from flask import Flask, request, jsonify
import os
import requests
from sshtunnel import SSHTunnelForwarder

app = Flask(__name__)

# Fetch the TRUSTED_HOST_DNS environment variable
trusted_host_dns = os.environ.get("TRUSTED_HOST_DNS")
app.logger.info("Trust Host DNS is: {}".format(trusted_host_dns))
if not trusted_host_dns:
    raise ValueError("Trusted Host environment variable not set")

# SSH Tunnel setup
server = SSHTunnelForwarder(
    (trusted_host_dns, 22),  # Remote SSH server for Trusted Host
    ssh_username="ubuntu",
    ssh_pkey="/etc/gatekeeper/my_terraform_key",
    remote_bind_address=(trusted_host_dns, 80),
    local_bind_address=("127.0.0.1", 5000),  # Internal access point
)

try:
    server.start()
    app.logger.info("SSH Tunnel successfully established to Trusted Host!")
except Exception as e:
    app.logger.error(f"Error establishing SSH Tunnel: {e}")
    raise

@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Hello, I am the Gatekeeper, and I am running!</h1>"

@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    try:
        trusted_host_url = f"http://{trusted_host_dns}/populate_tables"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /populate_tables: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_direct"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_direct: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_random", methods=["POST"])
def fetch_random():
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_random"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_random: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_customized", methods=["POST"])
def fetch_customized():
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_customized"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_customized: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
