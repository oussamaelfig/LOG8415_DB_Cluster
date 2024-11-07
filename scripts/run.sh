#!/bin/bash

# Check if SSH key pair exists; if not, create it
if [ ! -f "../infrastructure/my_terraform_key" ]; then
    echo "SSH key pair not found. Generating a new key pair..."
    ssh-keygen -t rsa -b 4096 -f ../infrastructure/my_terraform_key -N ""
    echo "SSH key pair generated."
    chmod 400 ../infrastructure/my_terraform_key
else
    echo "SSH key pair found. Using the existing key."
    sudo chmod 400 ../infrastructure/my_terraform_key
fi

# Get AWS credentials from user input
echo "Please provide your AWS Access Key: "
read AWS_ACCESS_KEY
echo "Please provide your AWS Secret Access Key: "
read AWS_SECRET_ACCESS_KEY
echo "Please provide your AWS Session Token: "
read AWS_SESSION_TOKEN

# Export the credentials to env_vars.sh for later use
echo "export AWS_ACCESS_KEY='$AWS_ACCESS_KEY'" > env_vars.sh
echo "export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY'" >> env_vars.sh
echo "export AWS_SESSION_TOKEN='$AWS_SESSION_TOKEN'" >> env_vars.sh

# Deploy the infrastructure
echo "Running create_instances.sh to initialize infrastructure..."
./create_instances.sh
if [ $? -ne 0 ]; then
    echo "Instance creation failed. Exiting."
    exit 1
fi

# Wait for instances to initialize
echo "Waiting for instances to initialize..."
sleep 120

# Function to check SSH connection
function check_ssh() {
    local ip=$1
    for i in {1..15}; do
        echo "Attempting to connect to instance $ip (attempt $i)..."
        if ssh -o StrictHostKeyChecking=no -i ../infrastructure/my_terraform_key ubuntu@$ip 'echo SSH connection successful'; then
            echo "Instance $ip is reachable."
            return 0
        else
            echo "Instance $ip is not reachable yet. Retrying in 10 seconds..."
            sleep 10
        fi
    done
    echo "Failed to connect to instance $ip after multiple attempts."
    return 1
}

# Source IP addresses
source ./ip_addresses.sh
echo "Loaded IPs and DNS:"
echo "MANAGER_IP=$MANAGER_IP, MANAGER_DNS=$MANAGER_DNS"
echo "WORKER_IPS=${WORKER_IPS[@]}, WORKER_DNS=${WORKER_DNS[@]}"
echo "PROXY_IP=$PROXY_IP, PROXY_DNS=$PROXY_DNS"
echo "GATEKEEPER_IP=$GATEKEEPER_IP, GATEKEEPER_DNS=$GATEKEEPER_DNS"
echo "TRUSTED_HOST_IP=$TRUSTED_HOST_IP, TRUSTED_HOST_DNS=$TRUSTED_HOST_DNS"

# Verify SSH connectivity for all instances
check_ssh "$MANAGER_IP"
check_ssh "$PROXY_IP"
check_ssh "$GATEKEEPER_IP"
check_ssh "$TRUSTED_HOST_IP"
for worker_ip in "${WORKER_IPS[@]}"; do
    check_ssh "$worker_ip"
done

# Check if Gatekeeper and Proxy services are up
function poll_service() {
    local url=$1
    local service_name=$2
    SECONDS=0
    TIMEOUT=300  # 5 minutes timeout

    echo "Waiting for $service_name service at $url to start..."

    while true; do
        http_status=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$url")

        if [ "$http_status" -eq 200 ]; then
            echo "$service_name service is now available."
            break
        fi

        if [ $SECONDS -ge $TIMEOUT ]; then
            echo "Timeout reached, $service_name service at $url is not available."
            return 1
        fi
        sleep 10
    done
}

# Poll Gatekeeper and Proxy services
poll_service "http://$GATEKEEPER_DNS/health_check" "Gatekeeper"
poll_service "http://$PROXY_DNS/health_check" "Proxy"

# Run requests for benchmarking directly after services are validated
echo "Setting up Gatekeeper DNS for requests..."
export GATEKEEPER_DNS=$GATEKEEPER_DNS

echo "Running send_requests.py for benchmarking..."
python3 ../requests/send_requests.py

echo -e "\nBenchmarking complete. All setup, testing, and benchmarking have been completed in one run."