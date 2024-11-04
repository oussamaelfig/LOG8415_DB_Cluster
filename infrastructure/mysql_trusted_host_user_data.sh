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

    # Pull and run Trusted Host container
    sudo docker pull oelfigha/trusted_host:latest
    sudo docker run -e PROXY_DNS="$PROXY_DNS" -p 80:5000 -v /home/ubuntu/my_terraform_key:/etc/trusted_host/my_terraform_key oelfigha/trusted_host:latest

} >> /var/log/progress.log 2>&1
