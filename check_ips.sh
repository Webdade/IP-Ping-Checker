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
# Ping settings
# ---------------------------------------------------------------------------
# A single ping packet is unreliable: when many hosts are checked back-to-back,
# random packet loss and ICMP rate-limiting cause reachable hosts to be marked
# "failed" at random (so the same IP can flip between runs). To avoid this we
# send a few packets and retry a few times, and only mark an IP as "failed"
# when EVERY attempt is lost.
PING_COUNT=1        # packets sent per attempt
PING_TIMEOUT=2      # seconds to wait for a reply, per attempt
PING_RETRIES=4      # number of attempts before declaring an IP failed

# Returns success (0) as soon as any ping attempt gets a reply, so reachable
# hosts are detected quickly; only truly unreachable hosts use all retries.
is_alive() {
    local ip="$1"
    local attempt
    for (( attempt = 1; attempt <= PING_RETRIES; attempt++ )); do
        if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$ip" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

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
: > "$OUTPUT_FILE"

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

# Read the file line by line. Each line may hold a single IP, or several IPs
# separated by commas (and/or spaces), so both formats below are accepted:
#     8.8.8.8
#     1.1.1.1, 9.9.9.9, 208.67.222.222
while IFS= read -r line || [ -n "$line" ]; do
    # Turn commas into spaces, then split the line into individual tokens.
    # `read -ra` splits on whitespace without triggering filename globbing.
    line="${line//,/ }"
    read -ra tokens <<< "$line"

    for ip in "${tokens[@]}"; do
        # Skip empty tokens (e.g. from a trailing comma or blank line)
        if [ -z "$ip" ]; then
            continue
        fi

        # Increment total counter
        ((total++))

        # Ping the IP, retrying a few times so a single dropped packet does
        # not wrongly mark a reachable host as failed.
        if is_alive "$ip"; then
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
    done
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
