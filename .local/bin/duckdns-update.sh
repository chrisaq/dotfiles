#!/bin/bash
# Path: ~/.local/bin/duckdns-update.sh

# Check if domain is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Replace dashes with dots in the domain name
DOMAIN=${DOMAIN//-/.}

# Read the token from the file
TOKEN_FILE="$HOME/.config/tokens/duckdns.token"
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found at $TOKEN_FILE"
    exit 1
fi
TOKEN=$(cat $TOKEN_FILE)

IP_FILE="/tmp/${DOMAIN}_current_ip.txt"  # Store IP separately for each domain

# Get the current external IP address
CURRENT_IP=$(curl -s http://checkip.amazonaws.com)

# Get the last known IP (if the file exists)
if [ -f $IP_FILE ]; then
    LAST_IP=$(cat $IP_FILE)
else
    LAST_IP=""
fi

# Only update DuckDNS if the IP has changed
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    echo "IP has changed. Updating DuckDNS for $DOMAIN..."
    echo $CURRENT_IP > $IP_FILE  # Save the new IP
    # Send the IP update to DuckDNS
    curl -s "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$CURRENT_IP"
else
    echo "IP for $DOMAIN has not changed. No update needed."
fi

