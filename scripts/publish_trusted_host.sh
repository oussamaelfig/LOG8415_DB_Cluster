#!/bin/bash
# Build the Docker image
docker build -f ../trusted_host/Dockerfile -t trusted_host ../trusted_host

# Tag the Docker image
docker tag trusted_host oelfigha/trusted_host:latest

# Push the Docker image to the repository
docker push oelfigha/trusted_host:latest