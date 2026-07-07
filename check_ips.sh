#!/bin/bash

# IP Ping Checker Script
# ---------------------------------------------------------------------------
# Reads IP addresses (or hostnames) from ips.txt and checks their connectivity
# using ping. Results are grouped: all reachable (OK) IPs are printed together
# in one block, and all unreachable (failed) IPs are printed together in another
# block. Full results are also saved to results.txt.
#
# Usage:
#   ./check_ips.sh          Show both OK and failed IPs (grouped)
#   ./check_ips.sh ok       Show only reachable (OK) IPs
#   ./check_ips.sh failed   Show only unreachable (failed) IPs
#   ./check_ips.sh --help   Show this help message
# ---------------------------------------------------------------------------

# Input and output files
INPUT_FILE="ips.txt"
OUTPUT_FILE="results.txt"

# ---------------------------------------------------------------------------
# Parse the filter argument (default: show everything)
# ---------------------------------------------------------------------------
FILTER="${1:-all}"
FILTER=$(echo "$FILTER" | tr '[:upper:]' '[:lower:]')

case "$FILTER" in
    all|ok|failed)
        ;;
    -h|--help|help)
        echo "Usage: $0 [ok|failed]"
        echo "  (no argument)  Show both OK and failed IPs (grouped)"
        echo "  ok             Show only reachable (OK) IPs"
        echo "  failed         Show only unreachable (failed) IPs"
        exit 0
        ;;
    *)
        echo "Error: unknown option '$1'" >&2
        echo "Usage: $0 [ok|failed]   (run '$0 --help' for details)" >&2
        exit 1
        ;;
esac

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!" >&2
    echo "Please create $INPUT_FILE with IP addresses (one per line)" >&2
    exit 1
fi

# Clear previous results if exists
> "$OUTPUT_FILE"

# Counter variables
total=0
success=0
failed=0

# Arrays to collect grouped results
ok_ips=()
failed_ips=()

# Progress messages go to stderr so that stdout stays a clean, copy-paste-able
# list of IP addresses (handy for redirecting or pasting into a chat message).
echo "Starting IP connectivity check..." >&2
echo "Reading from: $INPUT_FILE" >&2
echo "----------------------------------------" >&2

# Read each IP from the file
while IFS= read -r ip || [ -n "$ip" ]; do
    # Remove leading/trailing whitespace
    ip=$(echo "$ip" | xargs)

    # Skip empty lines
    if [ -z "$ip" ]; then
        continue
    fi

    # Increment total counter
    ((total++))

    # Ping the IP (1 packet, 2 second timeout)
    # Redirect output to /dev/null to suppress ping output
    if ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
        # IP is reachable
        echo "$ip OK" >> "$OUTPUT_FILE"
        echo "✓ $ip - OK" >&2
        ok_ips+=("$ip")
        ((success++))
    else
        # IP is not reachable
        echo "$ip failed" >> "$OUTPUT_FILE"
        echo "✗ $ip - failed" >&2
        failed_ips+=("$ip")
        ((failed++))
    fi
done < "$INPUT_FILE"

echo "----------------------------------------" >&2

# ---------------------------------------------------------------------------
# Helper functions to print each grouped block.
# The header goes to stderr and the bare IP list goes to stdout, so a command
# like `./check_ips.sh ok > alive.txt` produces a clean file of IPs only.
# ---------------------------------------------------------------------------
print_ok() {
    echo "✅ OK IPs ($success):" >&2
    for ip in "${ok_ips[@]}"; do
        echo "$ip"
    done
}

print_failed() {
    echo "❌ Failed IPs ($failed):" >&2
    for ip in "${failed_ips[@]}"; do
        echo "$ip"
    done
}

# ---------------------------------------------------------------------------
# Emit the requested block(s).
# ---------------------------------------------------------------------------
case "$FILTER" in
    ok)
        print_ok
        ;;
    failed)
        print_failed
        ;;
    all)
        print_ok
        echo "" >&2
        print_failed
        ;;
esac

# Print summary (to stderr so it does not pollute the IP list on stdout)
echo "----------------------------------------" >&2
echo "Ping check completed!" >&2
echo "Total IPs checked: $total" >&2
echo "Successful: $success" >&2
echo "Failed: $failed" >&2
echo "Results saved to: $OUTPUT_FILE" >&2
