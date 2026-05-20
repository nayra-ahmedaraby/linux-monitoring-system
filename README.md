# Linux Monitoring System 🐧

## Project Overview

**Linux Monitoring System** is a comprehensive system for monitoring the health and security of a Linux server. It provides an interactive dashboard that displays live resources, security issues, and alerts—all through a user-friendly command-line interface.

The system is written entirely in **Bash** and supports various Linux distributions (Debian, Ubuntu, Red Hat, CentOS, Kali, and others).

---

## ✨ Key Features

### 📊 Resource Monitoring
- **CPU**: Processor usage with warning and critical indicators
- **Memory (RAM)**: Memory consumption with customizable thresholds
- **Disk Space**: Storage capacity and usage information
- **Network**: Network interface details and connections
- **Load Average**: System load metrics (1m, 5m, 15m)

### 🔒 Security Monitoring
- **Service Health**: Monitoring critical services (SSH, Cron)
- **SSH Attempts**: Tracking failed and successful login attempts
- **Open Ports**: Identifying active and suspicious ports
- **User Management**: List of active users and sessions
- **File Integrity**: Comparing checksums of critical files (MD5/SHA256)
- **Zombie Processes**: Detecting orphaned processes

### 📝 Logging & Alerts
- **Centralized Logging**: Store all data in organized log files
- **Alert System**: Send alerts when thresholds are exceeded
- **Log Rotation**: Automatic management of log file sizes
- **Daily Reports**: Comprehensive daily system status reports

### 🎨 User Interface
- **Live Dashboard**: Real-time system status updates
- **Interactive Menu**: Easy access to all features
- **Color Coding**: Color-coded interface for easy readability

---

## 📁 Architecture & Project Structure

```
linux-monitoring-system/
│
├── monitor.sh                    # Main program (entry point)
├── config.conf                   # Shared configuration file
├── install.sh                    # Setup and preparation script
│
├── scripts/
│   ├── resources/                # System resource monitoring
│   │   ├── cpu.sh               # CPU information
│   │   ├── memory.sh            # Memory and Swap
│   │   ├── disk.sh              # Storage space
│   │   ├── network.sh           # Network interfaces
│   │   └── load.sh              # System load average
│   │
│   ├── security/                # Security checks
│   │   ├── services.sh          # Critical service status
│   │   ├── ssh_attempts.sh      # SSH login attempts
│   │   ├── open_ports.sh        # Active ports
│   │   ├── users.sh             # Users and sessions
│   │   ├── file_integrity.sh    # File checksums
│   │   └── zombies.sh           # Zombie processes
│   │
│   ├── ui/                      # User interface components
│   │   ├── colors.sh            # Color scheme and formatting
│   │   ├── progress_bar.sh      # Progress bars and graphs
│   │   ├── dashboard.sh         # Main dashboard
│   │   └── menu.sh              # Interactive menu
│   │
│   └── logging/                 # Logging and alerts
│       ├── log_writer.sh        # Log file writer
│       ├── log_rotate.sh        # Log rotation
│       ├── alerts.sh            # Alert system
│       └── daily_report.sh      # Daily reports
│
├── logs/                        # Log directory (auto-created)
│   └── .gitkeep
│
├── baseline/                    # File integrity baselines
│   └── .gitkeep
│
└── docs/
    ├── output_format.md         # Output format documentation
    └── final_report.pdf         # Final report
```

---

## 🚀 Quick Start

### Requirements
- Linux system (Debian, Ubuntu, Red Hat, CentOS, Kali, etc.)
- Bash 4.0+
- Standard utilities: `awk`, `grep`, `sed`, `ps`, `netstat`/`ss`

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nayra-ahmedaraby/linux-monitoring-system.git
   cd linux-monitoring-system
   ```

2. **Run the installation script:**
   ```bash
   bash install.sh
   ```
   This creates required directories and prepares the system for use.

### Basic Usage

**Display a single dashboard snapshot:**
```bash
./monitor.sh
```

**Live monitoring (continuous updates):**
```bash
./monitor.sh --watch
```
Updates every 5 seconds (configurable in `config.conf`)

**Interactive menu:**
```bash
./monitor.sh --menu
```

**Run the alert system:**
```bash
./monitor.sh --alerts
```

**Get help:**
```bash
./monitor.sh --help
```

---

## ⚙️ Configuration & Customization

All settings are in `config.conf`:

```bash
# Resource thresholds (percentage)
CPU_WARN_THRESHOLD=70          # Warning level
CPU_CRIT_THRESHOLD=90          # Critical level

RAM_WARN_THRESHOLD=75
RAM_CRIT_THRESHOLD=90

DISK_WARN_THRESHOLD=80
DISK_CRIT_THRESHOLD=95

# Services to monitor
MONITORED_SERVICES="sshd cron"

# Suspicious ports
SUSPICIOUS_PORTS="23 2323 4444 5555 31337"

# Refresh interval
REFRESH_INTERVAL=5             # seconds
```

---

## 📊 Sample Output

### Live Dashboard
```
╔════════════════════════════════════════════════════════╗
║       LINUX SYSTEM MONITORING DASHBOARD               ║
║              2024-05-20 14:32:45                      ║
╠════════════════════════════════════════════════════════╣
║ CPU      [████████░░] 85%  🔴 CRITICAL                ║
║ RAM      [███████░░░] 74%  🟡 WARNING                 ║
║ DISK     [██████░░░░] 61%  🟢 OK                      ║
║ LOAD AVG 1.45 (5m), 1.32 (15m)                        ║
║                                                        ║
║ 🔒 SECURITY STATUS:                                    ║
║   SSH Service       ✓ Running                         ║
║   Failed Logins     2 attempts in last hour           ║
║   Open Ports        8 active ports                    ║
║   File Integrity    ✓ All critical files intact       ║
╚════════════════════════════════════════════════════════╝
```

---

## 🔧 Design & Architecture

### Modular Design
Each component is responsible for a specific function:
- **Resources**: Collect system resource data
- **Security**: Perform security checks
- **UI**: Handle display and formatting
- **Logging**: Handle logging and alerts

### Centralized Configuration
- `config.conf`: All settings in one place
- `monitor.sh`: Single entry point
- `scripts/ui/colors.sh`: Central color handler

### Quality Standards
- ✅ Shellcheck compliant
- ✅ Comprehensive error handling
- ✅ Clear and documented comments
- ✅ Multi-distribution Linux support

---

## 📈 Use Cases

1. **Production Server Monitoring**: Track performance and resources in real-time
2. **Security Audits**: Detect threats and suspicious activity
3. **Compliance & Auditing**: Maintain comprehensive activity logs
4. **Incident Response**: Quickly identify and address issues
5. **Education & Training**: Learn Linux system administration

---

## 🤝 Project Team

This project is developed by second-year students from the Information Systems Department:

- **Member 1**: System resource monitoring (scripts/resources/)
- **Member 2**: Security checks (scripts/security/)
- **Member 3**: User interface components (scripts/ui/)
- **Member 4**: Logging and alerts (scripts/logging/)

---

## 📝 License

This project is open source and available for academic and educational use.

---

## 🐛 Issues & Feedback

To report bugs or suggest improvements:
- Open an issue on GitHub
- Contact the project team

---

## 📚 Additional Resources

- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Linux System Administration](https://linux.die.net/)
- [Network Monitoring Best Practices](https://www.oreilly.com/)

---

**Last Updated**: 2024-05-20  
**Version**: 1.0
