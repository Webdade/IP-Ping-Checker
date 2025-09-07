#!/bin/bash

# IP Ping Checker Script
# This script reads IP addresses from ips.txt and checks their connectivity
# Results are saved to results.txt with OK for reachable and failed for unreachable IPs

# Input and output files
INPUT_FILE="ips.txt"
OUTPUT_FILE="results.txt"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    echo "Please create $INPUT_FILE with IP addresses (one per line)"
    exit 1
fi

# Clear previous results if exists
> "$OUTPUT_FILE"

# Counter variables
total=0
success=0
failed=0

echo "Starting IP connectivity check..."
echo "Reading from: $INPUT_FILE"
echo "Writing to: $OUTPUT_FILE"
echo "----------------------------------------"

# Read each IP from the file
while IFS= read -r ip || [ -n "$ip" ]; do
    # Skip empty lines
    if [ -z "$ip" ]; then
        continue
    fi
    
    # Remove leading/trailing whitespace
    ip=$(echo "$ip" | xargs)
    
    # Increment total counter
    ((total++))
    
    # Ping the IP (1 packet, 2 second timeout)
    # Redirect output to /dev/null to suppress ping output
    if ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
        # IP is reachable
        echo "$ip OK" >> "$OUTPUT_FILE"
        echo "✓ $ip - OK"
        ((success++))
    else
        # IP is not reachable
        echo "$ip failed" >> "$OUTPUT_FILE"
        echo "✗ $ip - failed"
        ((failed++))
    fi
done < "$INPUT_FILE"

# Print summary
echo "----------------------------------------"
echo "Ping check completed!"
echo "Total IPs checked: $total"
echo "Successful: $success"
echo "Failed: $failed"
echo "Results saved to: $OUTPUT_FILE"