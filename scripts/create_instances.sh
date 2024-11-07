#!/bin/bash

# Access the environment variables
source env_vars.sh

# Change to the infrastructure directory
cd ../infrastructure

# Initialize and apply Terraform configuration
echo -e "Creating instances...\n"
terraform init -input=false  # Initialize Terraform without user input
terraform apply -auto-approve -input=false -var="AWS_ACCESS_KEY=$AWS_ACCESS_KEY" -var="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -var="AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" -var="private_key_path=../infrastructure/my_terraform_key"

# Ensure terraform apply completed successfully
if [ $? -ne 0 ]; then
    echo "Terraform apply failed. Exiting."
    exit 1
fi

# Install jq for JSON parsing
apt install jq -y

# Capture the IP addresses with correct output variable names
MANAGER_IP=$(terraform output -raw mysql_manager_ip)
WORKER_IPS=$(terraform output -json mysql_worker_ips | jq -r '.[]')
PROXY_IP=$(terraform output -raw mysql_proxy_ip)
GATEKEEPER_IP=$(terraform output -raw gatekeeper_ip)
TRUSTED_HOST_IP=$(terraform output -raw trusted_host_ip)

# Export the IPs to a file
echo "MANAGER_IP=$MANAGER_IP" > ../scripts/ip_addresses.sh
echo "WORKER_IPS=(${WORKER_IPS[@]})" >> ../scripts/ip_addresses.sh
echo "PROXY_IP=$PROXY_IP" >> ../scripts/ip_addresses.sh
echo "GATEKEEPER_IP=$GATEKEEPER_IP" >> ../scripts/ip_addresses.sh
echo "TRUSTED_HOST_IP=$TRUSTED_HOST_IP" >> ../scripts/ip_addresses.sh

# Convert IP addresses and distribute
cd ../scripts
./convert_ip_addresses.sh

# Convert to an array for easier access in the loop
WORKER_IPS=($WORKER_IPS)

for instance in $MANAGER_IP $PROXY_IP $GATEKEEPER_IP $TRUSTED_HOST_IP "${WORKER_IPS[@]}"; do
    echo "Waiting for instance $instance to become reachable..."
    until nc -z -v -w30 $instance 22 2>/dev/null; do
        echo "Instance $instance is not reachable yet. Retrying in 10 seconds..."
        sleep 10
    done
    echo "Instance $instance is reachable. Proceeding with file transfer."

    # Distribute the ip_addresses.sh file
    scp -o StrictHostKeyChecking=no -i ../infrastructure/my_terraform_key ip_addresses.sh ubuntu@$instance:/tmp/ip_addresses.sh
done
