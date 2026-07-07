# IP Ping Checker 🌐

A simple and efficient bash script to check the connectivity status of multiple IP addresses in bulk.

## 📋 Description

This bash script reads a list of IP addresses from a text file and checks their connectivity using ping. It provides a clear output showing which IPs are reachable and which are not, saving the results to a file for further analysis.

## ✨ Features

- **Bulk IP checking** - Process multiple IP addresses at once
- **Grouped output** - All reachable (OK) IPs are listed together in one block and all failed IPs in another, so each list can be copied in a single go
- **Filtering** - Show only the healthy IPs (`ok`) or only the failed IPs (`failed`) with a single argument
- **Copy-paste friendly** - The grouped IP lists print to `stdout` while progress and summary go to `stderr`, so `./check_ips.sh ok > alive.txt` produces a clean file of IPs only
- **Fast execution** - Uses minimal ping packets (1 packet per IP)
- **Live progress** - Shows real-time progress with visual indicators while checking
- **Result logging** - Saves all results to a text file
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

3. Check the full log in `results.txt`

> 💡 The IP lists are printed to `stdout` and the progress/summary lines to `stderr`.
> That means you can save a clean, ready-to-use list straight to a file:
> ```bash
> ./check_ips.sh ok > alive.txt        # only the healthy IPs, one per line
> ./check_ips.sh failed > dead.txt     # only the failed IPs, one per line
> ```

## 📝 Input Format

The `ips.txt` file should contain one IP address or hostname per line:
```
192.168.1.1
8.8.8.8
10.0.0.1
example.com
```

## 📊 Output Format

### Console Output (`./check_ips.sh`)

While checking, live progress is shown, then the results are printed in two
grouped blocks — all OK IPs together, followed by all failed IPs together:

```
Starting IP connectivity check...
Reading from: ips.txt
----------------------------------------
✓ 192.168.1.1 - OK
✗ 10.0.0.1 - failed
✓ 8.8.8.8 - OK
----------------------------------------
✅ OK IPs (2):
192.168.1.1
8.8.8.8

❌ Failed IPs (1):
10.0.0.1
----------------------------------------
Ping check completed!
Total IPs checked: 3
Successful: 2
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
```
192.168.1.1 OK
10.0.0.1 failed
8.8.8.8 OK
```

## ⚙️ Configuration

You can modify the following parameters in the script:

- **Ping count**: Change `-c 1` to increase the number of ping packets
- **Timeout**: Modify `-W 2` to adjust the timeout in seconds
- **Input file**: Change `INPUT_FILE` variable to use a different input file
- **Output file**: Change `OUTPUT_FILE` variable to use a different output file

## 🔧 Customization Examples

### Using custom file names:
```bash
# Edit the script and change these lines:
INPUT_FILE="my_ip_list.txt"
OUTPUT_FILE="connectivity_report.txt"
```

### Adjusting ping parameters for slow networks:
```bash
# Increase timeout to 5 seconds and send 3 packets:
ping -c 3 -W 5 "$ip"
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
- [ ] Implement parallel processing for faster execution
- [ ] Add DNS resolution for hostnames
- [ ] Create a web interface
- [ ] Add email notifications for failures
- [ ] Support for IPv6 addresses
- [ ] Integration with monitoring systems (Nagios, Zabbix)

---

**⭐ If you find this project useful, please consider giving it a star on GitHub!**