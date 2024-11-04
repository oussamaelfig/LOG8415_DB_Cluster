#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

{
    sudo apt update -y
    sudo apt upgrade -y

    # Install Docker for containerized Gatekeeper
    sudo apt install -y docker.io

    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    # Load IP addresses for configuration
    source /tmp/ip_addresses.sh

    # Pull and run the Gatekeeper container
    sudo docker pull oelfigha/gatekeeper:latest
    sudo docker run -e TRUSTED_HOST_DNS="$TRUSTED_HOST_DNS" -p 80:5000 -v /home/ubuntu/my_terraform_key:/etc/gatekeeper/my_terraform_key oelfigha/gatekeeper:latest

} >> /var/log/progress.log 2>&1
