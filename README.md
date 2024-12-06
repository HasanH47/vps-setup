# VPS Automated Setup Script

## Overview
This Bash script provides an automated, comprehensive setup for a secure and optimized Virtual Private Server (VPS) running Ubuntu, with the following key features:
- System package updates
- Security hardening
- Nginx web server installation
- MariaDB database setup
- PHP configuration
- SSL certificate installation
- Performance optimizations

## Prerequisites
- A fresh Ubuntu server (recommended: latest LTS version)
- Root or sudo access
- Internet connection

## Features

### Security
- UFW (Uncomplicated Firewall) configuration
- Fail2Ban intrusion prevention
- AppArmor security module
- SSH, HTTP, and HTTPS port configurations

### Web Stack
- Nginx web server
- MariaDB database
- Configurable PHP version
- Let's Encrypt SSL certificates

### Customization
The script allows you to interactively set:
- Database credentials
- Database name
- PHP version
- Domain name for SSL

## Usage

1. Clone the repository
```bash
git clone https://github.com/HasanH47/vps-setup.git
cd vps-setup
```

2. Make the script executable
```bash
chmod +x vps-setup.sh
```

3. Run the script with sudo
```bash
sudo ./vps-setup.sh
```

4. Follow the interactive prompts to:
   - Enter database root password
   - Create database user
   - Set database name
   - Choose PHP version
   - Configure domain for SSL

## Important Notes
- This script is intended for Ubuntu/Debian-based systems
- Always review the script before running
- Backup important data before running
- Modify domain and email placeholders before use

## Security Recommendations
- Use strong, unique passwords
- Keep the system and packages updated
- Regularly review and update security configurations

## Customization
You can modify the script to:
- Add additional software
- Change firewall rules
- Adjust Nginx and PHP configurations

## Disclaimer
Use this script at your own risk. Always test in a controlled environment first.

## Contributing
Contributions, issues, and feature requests are welcome!
