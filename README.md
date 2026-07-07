# IP Ping Checker 🌐

A simple and efficient bash script to check the connectivity status of multiple IP addresses in bulk.

## 📋 Description

This bash script reads a list of IP addresses from a text file and checks their connectivity using ping. It provides a clear output showing which IPs are reachable and which are not, saving the results to a file for further analysis.

## ✨ Features

- **Bulk IP checking** - Process multiple IP addresses at once
- **Parallel & fast** - Pings up to `MAX_PARALLEL` IPs (200 by default) at the same time instead of one-by-one, so hundreds of IPs finish in seconds
- **Flexible input** - Accepts one IP per line **or** several IPs on one line separated by commas (`,`) — the two styles can be mixed
- **Grouped output** - All reachable (OK) IPs are listed together in one block and all failed IPs in another, so each list can be copied in a single go
- **No interleaving** - Nothing is printed while pinging, so OK and failed results are never mixed together — you only see the two clean blocks at the end
- **Filtering** - Show only the healthy IPs (`ok`) or only the failed IPs (`failed`) with a single argument
- **Copy-paste friendly** - The grouped IP lists print to `stdout` while progress and summary go to `stderr`, so `./check_ips.sh ok > alive.txt` produces a clean file of IPs only
- **Reliable results** - Sends several packets per IP (5 by default) and classifies it by how many reply, so random packet loss doesn't randomly flip an IP between `OK` and `failed` on different runs
- **Result logging** - Saves all results, including the reply count (e.g. `5/5`), to a text file
- **Summary statistics** - Displays total, successful, and failed connections
- **Error handling** - Validates input file existence
- **Whitespace handling** - Automatically trims whitespace from IP addresses

## 📦 Requirements

- Bash shell (version 3.0 or higher)
- Linux/Unix environment (macOS, Ubuntu, CentOS, etc.)
- `ping` command available in system PATH
- Read/write permissions in the working directory

## 🚀 Installation

### One-line install (recommended)

Download the script into the current directory and make it executable:

```bash
curl -fsSL https://raw.githubusercontent.com/Webdade/IP-Ping-Checker/main/check_ips.sh -o check_ips.sh && chmod +x check_ips.sh
```

> Using `wget` instead of `curl`:
> ```bash
> wget -qO check_ips.sh https://raw.githubusercontent.com/Webdade/IP-Ping-Checker/main/check_ips.sh && chmod +x check_ips.sh
> ```

### Manual install (clone the repo)

1. Clone this repository:
```bash
git clone https://github.com/Webdade/IP-Ping-Checker.git
cd IP-Ping-Checker
```

2. Make the script executable:
```bash
chmod +x check_ips.sh
```

## 📖 Usage

1. Create an input file named `ips.txt` with IP addresses (one per line):
```text
192.168.1.1
8.8.8.8
10.0.0.1
172.16.0.1
google.com
```

2. Run the script in the mode you need:

| Command | What it shows |
| --- | --- |
| `./check_ips.sh` | Both groups: the OK IPs together, then the failed IPs together |
| `./check_ips.sh ok` | **Only** the reachable (OK) IPs |
| `./check_ips.sh failed` | **Only** the unreachable (failed) IPs |
| `./check_ips.sh --help` | Show the usage help |

An IP is reported **OK** only when it replies to at least `REQUIRED_OK` of the
`PING_COUNT` packets (by default, all **5 of 5**); otherwise it is reported
**failed**. All IPs are pinged in parallel and the two grouped lists are shown
once everything finishes.

3. Check the full log in `results.txt`

> 💡 The IP lists are printed to `stdout` and the progress/summary lines to `stderr`.
> That means you can save a clean, ready-to-use list straight to a file:
> ```bash
> ./check_ips.sh ok > alive.txt        # only the healthy IPs, one per line
> ./check_ips.sh failed > dead.txt     # only the failed IPs, one per line
> ```

## 📝 Input Format

The `ips.txt` file can list one IP address (or hostname) per line:
```
192.168.1.1
8.8.8.8
10.0.0.1
example.com
```

...or you can put several IPs on the same line separated by commas (`,`).
Both styles can even be mixed in the same file:
```
192.168.1.1, 8.8.8.8, 10.0.0.1
example.com
1.1.1.1,9.9.9.9
```
Extra spaces around the commas and a trailing comma are handled automatically.

## 📊 Output Format

### Console Output (`./check_ips.sh`)

Nothing is printed while pinging (so OK and failed never mix). Once every IP
has been checked, the results are printed in two grouped blocks — all OK IPs
together, followed by all failed IPs together:

```
Starting IP connectivity check...
Reading from: ips.txt (3 IPs)
Pinging up to 200 at a time, 5 packets each; please wait...
----------------------------------------
✅ OK IPs (2):
192.168.1.1
8.8.8.8

❌ Failed IPs (1):
10.0.0.1
----------------------------------------
Ping check completed!
Total IPs checked: 3
Successful (>= 5/5 replies): 2
Failed: 1
Results saved to: results.txt
```

### Filtered Output (`./check_ips.sh ok` / `./check_ips.sh failed`)

Only the requested group is printed as a clean list — perfect for copying into
a chat message or piping into another command:

```
$ ./check_ips.sh ok
✅ OK IPs (2):
192.168.1.1
8.8.8.8

$ ./check_ips.sh failed
❌ Failed IPs (1):
10.0.0.1
```

### File Output (results.txt)

Each line records the IP, its verdict, and how many of the packets replied:
```
192.168.1.1 OK 5/5
8.8.8.8 OK 5/5
10.0.0.1 failed 0/5
```

## ⚙️ Configuration

You can modify the following variables at the top of the script:

- **`PING_COUNT`**: Number of ping packets sent to each IP (default `5`)
- **`PING_TIMEOUT`**: Seconds to wait for each reply (default `2`)
- **`REQUIRED_OK`**: Replies needed (out of `PING_COUNT`) for an IP to count as `OK` (default `5`, i.e. all of them)
- **`MAX_PARALLEL`**: How many IPs to ping at the same time (default `200`)
- **`INPUT_FILE`**: Use a different input file (default `ips.txt`)
- **`OUTPUT_FILE`**: Use a different output file (default `results.txt`)

### ⚡ How it decides OK vs. failed (and why it's reliable)

Every IP is pinged **in parallel** with `PING_COUNT` packets. It is reported
`OK` only when at least `REQUIRED_OK` of those packets reply, and `failed`
otherwise. With the defaults, an IP is `OK` only if it answers **all 5** packets
and `failed` if it answers fewer.

Sending several spaced-out packets (instead of one rapid-fire packet per host)
avoids the random packet loss / **ICMP rate-limiting** that used to make the
*same* IP flip between `OK` and `failed` on different runs. The exact reply
count is saved to `results.txt` (e.g. `OK 5/5`, `failed 0/5`) so you can spot
flaky hosts with partial loss.

> - Want to be more forgiving (treat a host as `OK` if it answers *most*
>   packets)? Lower `REQUIRED_OK`, e.g. `REQUIRED_OK=3`.
> - Scanning a very large list and want it even faster? Raise `MAX_PARALLEL`.
> - On slow / high-latency links, raise `PING_TIMEOUT`.

## 🔧 Customization Examples

### Using custom file names:
```bash
# Edit the script and change these lines:
INPUT_FILE="my_ip_list.txt"
OUTPUT_FILE="connectivity_report.txt"
```

### Tuning strictness and speed:
```bash
# Stricter: require a perfect 5/5, ping fewer hosts at a time
REQUIRED_OK=5
MAX_PARALLEL=100

# More forgiving + faster: OK if at least 3 of 5 reply, 400 in parallel
PING_COUNT=5
REQUIRED_OK=3
MAX_PARALLEL=400
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Known Issues

- On some systems, ping might require root privileges for certain operations
- Windows systems require WSL (Windows Subsystem for Linux) or Git Bash
- Some networks may block ICMP packets, causing false negatives

## 💡 Tips

- For large IP lists (1000+), consider running the script in the background:
  ```bash
  nohup ./check_ips.sh &
  ```
- To check only specific subnets, pre-filter your IP list:
  ```bash
  grep "^192.168." all_ips.txt > ips.txt
  ```
- For continuous monitoring, use with cron:
  ```bash
  */5 * * * * /path/to/check_ips.sh
  ```

## 📮 Support

If you encounter any issues or have questions, please [open an issue](https://github.com/Webdade/IP-Ping-Checker/issues) on GitHub.

## 🙏 Acknowledgments

- Thanks to all contributors who have helped improve this script
- Inspired by the need for simple network monitoring tools

## 📈 Roadmap

- [ ] Add support for CSV output format
- [x] Implement parallel processing for faster execution
- [ ] Add DNS resolution for hostnames
- [ ] Create a web interface
- [ ] Add email notifications for failures
- [ ] Support for IPv6 addresses
- [ ] Integration with monitoring systems (Nagios, Zabbix)

---

**⭐ If you find this project useful, please consider giving it a star on GitHub!**