#!/bin/bash
# Build the Docker image
docker build -f ../gatekeeper/Dockerfile -t gatekeeper ../gatekeeper

# Tag the Docker image
docker tag gatekeeper oelfigha/gatekeeper:latest

# Push the Docker image to the repository
docker push oelfigha/gatekeeper:latest