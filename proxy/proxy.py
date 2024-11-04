import subprocess
from flask import Flask, request, jsonify
from sshtunnel import SSHTunnelForwarder
import mysql.connector
import os
import random
import threading

app = Flask(__name__)

# Configuration for the MySQL Manager Node
manager_db_config = {
    "host": os.environ.get("MANAGER_DNS"),  # Manager IP from environment variable
    "user": "root",
    "password": "",  # Ensure this matches the manager's MySQL setup
    "database": "main_db",
}

# Retrieve and validate the list of worker DNS addresses from environment variables
worker_dns_list = os.environ.get("WORKER_DNS", "").split(",")
if not worker_dns_list:
    raise ValueError("Worker DNS list is empty or not set")

# Global variables for SSH tunnels and request counters
random_ssh_tunnel = None
customized_ssh_tunnel = None
random_request_counter = 0


def create_ssh_tunnel(target_node):
    """
    Creates an SSH tunnel to the specified target node.
    """
    try:
        tunnel = SSHTunnelForwarder(
            (manager_db_config["host"], 22),
            ssh_username="ubuntu",
            ssh_pkey="/etc/proxy/my_terraform_key",
            remote_bind_address=(target_node, 3306),
            local_bind_address=("127.0.0.1", 9000),
        )
        tunnel.start()
        app.logger.info("SSH tunnel established to {}".format(target_node))
        return tunnel
    except Exception as e:
        app.logger.error(f"Failed to establish SSH tunnel to {target_node}: {e}")
        return None


def ping_worker_node(worker_node):
    """
    Pings a worker node to determine response time.
    """
    try:
        response = subprocess.run(
            ["ping", "-c", "1", worker_node],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        output = response.stdout.decode()
        time_taken = output.split("time=")[1].split(" ms")[0]
        return float(time_taken)
    except Exception as e:
        app.logger.error(f"Ping to {worker_node} failed: {e}")
        return float("inf")


def initialize_random_ssh_tunnel():
    """
    Initializes an SSH tunnel to a randomly chosen worker node.
    """
    global random_ssh_tunnel
    chosen_worker_node = random.choice(worker_dns_list)
    random_ssh_tunnel = create_ssh_tunnel(chosen_worker_node)
    app.logger.info("Random SSH tunnel to {} established".format(chosen_worker_node))


# Start the thread to initialize a random SSH tunnel
threading.Thread(target=initialize_random_ssh_tunnel).start()


@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Proxy is running! Manager DNS is {}.</h1>".format(manager_db_config["host"])


@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    """
    Populates specified tables with data on the manager node.
    """
    data = request.json
    sql_template = data.get("sql")
    table_names = ["direct_table", "random_table", "customized_table"]

    if not sql_template:
        return jsonify({"error": "No SQL query provided"}), 400

    target_table = table_names[(random_request_counter // 20) % len(table_names)]
    sql = sql_template.format(table=target_table)

    try:
        conn = mysql.connector.connect(**manager_db_config)
        cursor = conn.cursor()
        cursor.execute(sql)
        conn.commit()
        return jsonify({"message": f"Query executed in {target_table}"}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    """
    Fetches data directly from the manager node.
    """
    data = request.json
    sql = data.get("sql")

    if not sql:
        return jsonify({"error": "No SQL query provided"}), 400

    try:
        conn = mysql.connector.connect(**manager_db_config)
        cursor = conn.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        return jsonify(result), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/fetch_random", methods=["POST"])
def fetch_random():
    """
    Fetches data from a randomly chosen worker node.
    """
    global random_ssh_tunnel, random_request_counter
    data = request.json
    sql = data.get("sql")

    if not sql:
        return jsonify({"error": "No SQL query provided"}), 400

    if random_ssh_tunnel is None or not random_ssh_tunnel.is_active:
        return jsonify({"error": "SSH tunnel is not active"}), 500

    try:
        conn = mysql.connector.connect(
            host="127.0.0.1",
            port=random_ssh_tunnel.local_bind_port,
            user="root",
            password="",
            database="main_db",
        )
        cursor = conn.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        return jsonify(result), 200
    except mysql.connector.Error as err:
        return jsonify({"error": f"MySQL Error: {str(err)}"}), 500
    finally:
        random_request_counter += 1
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/fetch_customized", methods=["POST"])
def fetch_customized():
    """
    Fetches data from the worker node with the lowest ping time.
    """
    data = request.json
    sql = data.get("sql")

    if not sql:
        return jsonify({"error": "No SQL query provided"}), 400

    try:
        ping_times = {node: ping_worker_node(node) for node in worker_dns_list}
        best_node = min(ping_times, key=ping_times.get)
        customized_ssh_tunnel = create_ssh_tunnel(best_node)

        conn = mysql.connector.connect(
            host="127.0.0.1",
            port=customized_ssh_tunnel.local_bind_port,
            user="root",
            password="",
            database="main_db",
        )
        cursor = conn.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        return jsonify(result), 200
    except mysql.connector.Error as err:
        return jsonify({"error": f"MySQL Error: {str(err)}"}), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
