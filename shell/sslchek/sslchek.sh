#!/bin/bash

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain> [port]"
    exit 1
fi

# Set the port to 443 if not provided
PORT=${2:-443}

# Fetch the SSL certificate expiry date
data=$(echo | openssl s_client -servername "$1" -connect "$1:$PORT" 2>/dev/null | openssl x509 -in /dev/stdin -noout -enddate 2>/dev/null)

# Check if data was retrieved successfully
if [ -z "$data" ]; then
    echo "Failed to retrieve the SSL certificate information for $1"
    exit 1
fi

# Extract the expiration date from the data
ssl_expiry_date=$(echo "$data" | sed -e 's#notAfter=##')

# Convert the expiration date to UNIX timestamp (seconds since 1970-01-01)
if date --version &>/dev/null; then
    # Linux date command
    ssldate=$(date -d "$ssl_expiry_date" '+%s')
else
    # macOS date command
    ssldate=$(date -j -f "%b %d %T %Y" "$ssl_expiry_date" '+%s')
fi

# Get the current date in UNIX timestamp
nowdate=$(date '+%s')

# Calculate the difference in days
diff=$((ssldate - nowdate))
remaining_days=$((diff / 86400))

# Output the remaining days
echo "Days until SSL certificate expires: $remaining_days"


### Shell Execute Command
# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/refs/heads/main/shell/sslchek/sslchek.sh | bash -s scbyun.com
