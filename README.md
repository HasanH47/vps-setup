<div align="center">
    <img src="https://img.shields.io/badge/Server-Ubuntu-orange?style=for-the-badge&logo=ubuntu" alt="Ubuntu Server"/>
    <img src="https://img.shields.io/badge/Nginx-Web%20Server-green?style=for-the-badge&logo=nginx" alt="Nginx"/>
    <img src="https://img.shields.io/badge/MariaDB-Database-blue?style=for-the-badge&logo=mariadb" alt="MariaDB"/>
    <img src="https://img.shields.io/badge/PHP-Scripting-purple?style=for-the-badge&logo=php" alt="PHP"/>
</div>

# 🚀 VPS Automated Setup Script

A comprehensive Bash script for quickly setting up a secure and optimized Virtual Private Server (VPS) with Nginx, MariaDB, PHP, and SSL.

## 🌐 Repository
**GitHub:** [https://github.com/HasanH47/vps-setup](https://github.com/HasanH47/vps-setup)

## ✨ Features

### 🔒 Security
- UFW Firewall configuration
- Fail2Ban intrusion prevention
- AppArmor security module
- Secure SSH, HTTP, and HTTPS configurations

### 🖥️ Web Stack
- Nginx web server
- MariaDB database
- Configurable PHP version (8.x)
- Let's Encrypt SSL certificates
- Performance optimizations

## 🛠️ Prerequisites
- Ubuntu server (latest LTS recommended)
- Root/sudo access
- Internet connection

## 📦 Installation

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

## 🔧 Configuration Prompts
During execution, you'll be asked to provide:
- Database root password
- Database username
- Database user password
- Database name
- PHP version
- Domain name
- Admin email for Let's Encrypt

## 🛡️ Security Best Practices
- Use strong, unique passwords
- Regularly update system packages
- Review firewall and security settings periodically

## 🔬 Customization
You can modify the script to:
- Add additional software packages
- Adjust firewall rules
- Customize Nginx and PHP configurations

## 📋 Dependencies
<div>
    <img src="https://img.shields.io/badge/curl-Installed-brightgreen?style=flat-square" alt="curl"/>
    <img src="https://img.shields.io/badge/wget-Installed-brightgreen?style=flat-square" alt="wget"/>
    <img src="https://img.shields.io/badge/git-Installed-brightgreen?style=flat-square" alt="git"/>
    <img src="https://img.shields.io/badge/vim-Installed-brightgreen?style=flat-square" alt="vim"/>
    <img src="https://img.shields.io/badge/ufw-Installed-brightgreen?style=flat-square" alt="ufw"/>
</div>

## ⚠️ Disclaimer
**Use this script at your own risk. Always test in a controlled environment first.**

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! 
Please open an issue or submit a pull request.

## 📞 Contact
For questions or support, please open a GitHub issue.

---

<div align="center">
    <sub>Created with ❤️ by HasanH47</sub>
</div>
