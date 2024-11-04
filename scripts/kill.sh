#!/bin/bash

# Access the environment variables
source env_vars.sh

echo -e "Destroying all instances...\n"

cd ../infrastructure

# Destroy the infrastructure
terraform destroy -auto-approve -var="AWS_ACCESS_KEY=$AWS_ACCESS_KEY" -var="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -var="AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

# Clear IP and environment variables
> ../scripts/ip_addresses.sh
> ../scripts/env_vars.sh

echo -e "Everything was deleted successfully\n"
echo -e "-----------\n"
