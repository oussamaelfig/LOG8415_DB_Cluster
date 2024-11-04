import os
import requests

# Fetch the GATEKEEPER_DNS environment variable
gatekeeper_dns = os.environ.get("GATEKEEPER_DNS")
print("Gatekeeper DNS is: {}".format(gatekeeper_dns))
if not gatekeeper_dns:
    raise ValueError("GATEKEEPER_DNS environment variable not set")

# Define URLs for different operations in the Gatekeeper service
GATEKEEPER_POPULATE_URL = f"http://{gatekeeper_dns}/populate_tables"
GATEKEEPER_DIRECT_URL = f"http://{gatekeeper_dns}/fetch_direct"
GATEKEEPER_RANDOM_URL = f"http://{gatekeeper_dns}/fetch_random"
GATEKEEPER_CUSTOMIZED_URL = f"http://{gatekeeper_dns}/fetch_customized"

# Function to send a specified number of write requests to a table
def send_write_sql_requests(table_name, num_requests):
    write_query = f"INSERT INTO {table_name} (column1, column2) VALUES ('column1_value', 'column2_value')"
    print(f"Sending {num_requests} write requests to {table_name}...")

    for i in range(num_requests):
        response = requests.post(GATEKEEPER_POPULATE_URL, json={"sql": write_query})
        if response.status_code != 200:
            print(f"Error executing write query for {table_name}: {write_query}")
        else:
            print(f"Write request {i + 1}/{num_requests} to {table_name} successful.")

    print(f"Completed sending {num_requests} write requests to {table_name}.")

# Function to send 1000 read requests to the direct_table
def send_read_sql_requests_direct(num_requests):
    read_query = "SELECT * FROM direct_table LIMIT 1"
    print(f"Sending {num_requests} direct read requests to direct_table...")

    for i in range(num_requests):
        response = requests.post(GATEKEEPER_DIRECT_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing direct read query: {read_query}")
        else:
            response_data = response.json()
            print(f"Read direct request {i + 1}/{num_requests} successful. Response: {response_data}")

    print("Completed sending direct read requests to direct_table.")

# Function to send 1000 read requests to random_table
def send_read_sql_requests_random(num_requests):
    read_query = "SELECT * FROM random_table LIMIT 1"
    print(f"Sending {num_requests} random read requests to random_table...")

    for i in range(num_requests):
        response = requests.post(GATEKEEPER_RANDOM_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing random read query: {read_query}")
        else:
            response_data = response.json()
            print(f"Read random request {i + 1}/{num_requests} successful. Response: {response_data}")

    print("Completed sending random read requests to random_table.")

# Function to send 1000 read requests to customized_table
def send_read_sql_requests_customized(num_requests):
    read_query = "SELECT * FROM customized_table LIMIT 1"
    print(f"Sending {num_requests} customized read requests to customized_table...")

    for i in range(num_requests):
        response = requests.post(GATEKEEPER_CUSTOMIZED_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing customized read query: {read_query}")
        else:
            response_data = response.json()
            print(f"Read customized request {i + 1}/{num_requests} successful. Response: {response_data}")

    print("Completed sending customized read requests to customized_table.")

def main():
    print("Starting SQL write and read requests...")

    # Send 1000 write requests for each table
    for table in ["direct_table", "random_table", "customized_table"]:
        send_write_sql_requests(table, 1000)

    print("Finished populating tables.")

    # Send 1000 read requests for each access pattern
    print("Sending 1000 direct read requests...")
    send_read_sql_requests_direct(1000)

    print("Sending 1000 random read requests...")
    send_read_sql_requests_random(1000)

    print("Sending 1000 customized read requests...")
    send_read_sql_requests_customized(1000)

    print("All requests completed.")

if __name__ == "__main__":
    main()
