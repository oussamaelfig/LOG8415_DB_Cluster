from flask import Flask, request, jsonify
import os
import requests
from sshtunnel import SSHTunnelForwarder

app = Flask(__name__)

# Fetch the PROXY_DNS environment variable
proxy_dns = os.environ.get("PROXY_DNS")
if not proxy_dns:
    raise ValueError("PROXY_DNS environment variable not set")

# SSH Tunnel setup
server = SSHTunnelForwarder(
    (proxy_dns, 22),  # Remote SSH server
    ssh_username="ubuntu",
    ssh_pkey="/etc/trusted_host/my_terraform_key",
    remote_bind_address=(proxy_dns, 80),  # Proxy server port
    local_bind_address=("127.0.0.1", 80),
)

try:
    server.start()  # Start SSH tunnel
    app.logger.info("SSH Tunnel successfully established to Proxy")
except Exception as e:
    app.logger.error(f"Error establishing SSH Tunnel to Proxy: {e}")
    raise

@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Trusted Host app is running! Connected to Proxy at {}.</h1>".format(
        proxy_dns
    )

@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    """
    Forwards a request to populate tables to the Proxy.
    """
    try:
        proxy_url = f"http://127.0.0.1:80/populate_tables"
        response = requests.post(proxy_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /populate_tables: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    """
    Forwards a direct fetch request to the Proxy.
    """
    try:
        proxy_url = f"http://127.0.0.1:80/fetch_direct"
        response = requests.post(proxy_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_direct: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_random", methods=["POST"])
def fetch_random():
    """
    Forwards a random fetch request to the Proxy.
    """
    try:
        proxy_url = f"http://127.0.0.1:80/fetch_random"
        response = requests.post(proxy_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_random: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/fetch_customized", methods=["POST"])
def fetch_customized():
    """
    Forwards a customized fetch request to the Proxy.
    """
    try:
        proxy_url = f"http://127.0.0.1:80/fetch_customized"
        response = requests.post(proxy_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_customized: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
