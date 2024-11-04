#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

{
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y docker.io

    # Start Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Source IP addresses
    source /tmp/ip_addresses.sh
    WORKER_DNS_STRING=$(IFS=,; echo "${WORKER_DNS[*]}")

    # Pull and run the Proxy container
    sudo docker pull oelfigha/proxy:latest
    sudo docker run -e MANAGER_DNS="$MANAGER_DNS" -e WORKER_DNS="$WORKER_DNS_STRING" -p 80:5000 -v /home/ubuntu/my_terraform_key:/etc/proxy/my_terraform_key oelfigha/proxy:latest

} >> /var/log/progress.log 2>&1
