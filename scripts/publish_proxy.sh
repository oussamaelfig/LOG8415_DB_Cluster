#!/bin/bash
# Build the Docker image
docker build -f ../proxy/Dockerfile -t proxy ../proxy

# Tag the Docker image
docker tag proxy oelfigha/proxy:latest

# Push the Docker image to the repository
docker push oelfigha/proxy:latest
