#!/bin/bash

# Access the IP addresses
source ip_addresses.sh

check_service() {
  local url=$1
  http_status_code=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$url")
  echo $http_status_code
}

poll_service() {
  local url=$1
  local service_name=$2
  SECONDS=0
  TIMEOUT=300 # Set a 5-minute timeout

  echo "Waiting for $service_name service at $url to start..."

  while true; do
      http_status=$(check_service $url)

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

# Check Gatekeeper service
poll_service "http://$GATEKEEPER_DNS/health_check" "Gatekeeper"

# Check Proxy service after Gatekeeper is up
echo "Waiting before checking the Proxy service..."
sleep 60
poll_service "http://$PROXY_DNS/health_check" "Proxy"
