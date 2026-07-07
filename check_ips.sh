#!/bin/bash

# IP Ping Checker Script
# ---------------------------------------------------------------------------
# Reads IP addresses (or hostnames) from ips.txt and pings them IN PARALLEL,
# then prints the results grouped: all reachable (OK) IPs together in one
# block, and all unreachable (failed) IPs together in another block. Nothing is
# printed while pinging, so OK and failed are never mixed together. Full
# results are also saved to results.txt.
#
# Each IP is pinged with PING_COUNT packets. It is reported OK only when at
# least REQUIRED_OK of those packets reply; otherwise it is reported failed.
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
# Ping / performance settings  (tune these to taste)
# ---------------------------------------------------------------------------
PING_COUNT=5        # number of ping packets sent to each IP
PING_TIMEOUT=2      # seconds to wait for each reply
REQUIRED_OK=5       # replies needed (out of PING_COUNT) for an IP to count as OK
MAX_PARALLEL=200    # how many IPs to ping at the same time

# Ping one IP and print "<received> <ip>", where <received> is how many of the
# PING_COUNT packets came back. Works with both iputils and busybox ping.
check_one() {
    local ip="$1" out received
    out=$(ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$ip" 2>/dev/null)
    received=$(printf '%s\n' "$out" \
        | grep -oE '[0-9]+ (packets )?received' \
        | grep -oE '^[0-9]+' | head -n1)
    printf '%s %s\n' "${received:-0}" "$ip"
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

# ---------------------------------------------------------------------------
# Read every IP into the all_ips array. Each line may hold a single IP, or
# several IPs separated by commas (and/or spaces), so both formats work:
#     8.8.8.8
#     1.1.1.1, 9.9.9.9, 208.67.222.222
# ---------------------------------------------------------------------------
all_ips=()
while IFS= read -r line || [ -n "$line" ]; do
    line="${line//,/ }"
    read -ra tokens <<< "$line"
    for ip in "${tokens[@]}"; do
        [ -n "$ip" ] && all_ips+=("$ip")
    done
done < "$INPUT_FILE"

total=${#all_ips[@]}
if [ "$total" -eq 0 ]; then
    echo "No IP addresses found in $INPUT_FILE" >&2
    exit 1
fi

# Clear previous results
: > "$OUTPUT_FILE"

# Progress goes to stderr so stdout stays a clean, copy-paste-able IP list.
echo "Starting IP connectivity check..." >&2
echo "Reading from: $INPUT_FILE ($total IPs)" >&2
echo "Pinging up to $MAX_PARALLEL at a time, $PING_COUNT packets each; please wait..." >&2
echo "----------------------------------------" >&2

# ---------------------------------------------------------------------------
# Ping all IPs in parallel. Each check writes "<received> <ip>" to its own
# index-named temp file so the results can be read back in the original order.
# Nothing is printed here, so OK and failed can never appear interleaved.
# ---------------------------------------------------------------------------
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ip-ping.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

idx=0
for ip in "${all_ips[@]}"; do
    check_one "$ip" > "$tmpdir/$(printf '%08d' "$idx")" &
    ((idx++))
    # Throttle: once MAX_PARALLEL pings are in flight, wait for them to finish
    if (( idx % MAX_PARALLEL == 0 )); then
        wait
    fi
done
wait

# ---------------------------------------------------------------------------
# Collect the results (in the original order) and split into the two groups.
# ---------------------------------------------------------------------------
success=0
failed=0
ok_ips=()
failed_ips=()

for f in "$tmpdir"/*; do
    read -r received ip < "$f"
    received=${received:-0}
    [ -z "$ip" ] && continue
    if (( received >= REQUIRED_OK )); then
        ok_ips+=("$ip")
        ((success++))
        echo "$ip OK ${received}/${PING_COUNT}" >> "$OUTPUT_FILE"
    else
        failed_ips+=("$ip")
        ((failed++))
        echo "$ip failed ${received}/${PING_COUNT}" >> "$OUTPUT_FILE"
    fi
done

# ---------------------------------------------------------------------------
# Print each grouped block. The header goes to stderr and the bare IP list to
# stdout, so `./check_ips.sh ok > alive.txt` yields a clean file of IPs only.
# ---------------------------------------------------------------------------
print_ok() {
    echo "✅ OK IPs ($success):" >&2
    ((success > 0)) && printf '%s\n' "${ok_ips[@]}"
}

print_failed() {
    echo "❌ Failed IPs ($failed):" >&2
    ((failed > 0)) && printf '%s\n' "${failed_ips[@]}"
}

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
echo "Successful (>= $REQUIRED_OK/$PING_COUNT replies): $success" >&2
echo "Failed: $failed" >&2
echo "Results saved to: $OUTPUT_FILE" >&2
