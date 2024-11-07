#!/bin/bash

# Check if SSH key pair exists; if not, create it
if [ ! -f "../infrastructure/my_terraform_key" ]; then
    echo "SSH key pair not found. Generating a new key pair..."
    ssh-keygen -t rsa -b 4096 -f ../infrastructure/my_terraform_key -N ""
    echo "SSH key pair generated."
    
    # Set the correct permissions immediately after generating the key
    chmod 400 ../infrastructure/my_terraform_key
else
    echo "SSH key pair found. Using the existing key."
    
    # Ensure the key has the correct permissions
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

# Check if IPs were generated successfully
if [ $? -ne 0 ]; then
    echo "Instance creation failed. Exiting."
    exit 1
fi

# Wait before testing SSH connection
echo "Waiting for instances to initialize..."
sleep 120

# Retry SSH connection to check if instances are reachable
function check_ssh() {
  local ip=$1
  for i in {1..15}; do
    echo "Attempting to connect to instance $ip (attempt $i)..."
    if ssh -o StrictHostKeyChecking=no -i ~/ssh_keys/my_terraform_key ubuntu@$ip 'echo SSH connection successful'; then
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

# Test each instance's reachability using SSH
source ./ip_addresses.sh

check_ssh "$MANAGER_IP"
check_ssh "$PROXY_IP"
check_ssh "$GATEKEEPER_IP"
check_ssh "$TRUSTED_HOST_IP"

for worker_ip in "${WORKER_IPS[@]}"; do
  check_ssh "$worker_ip"
done

echo -e "Assignment deployment complete.\n"
