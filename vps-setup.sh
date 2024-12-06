#!/bin/bash

# Function to log errors and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to validate input
validate_input() {
    local input="$1"
    local error_msg="$2"
    if [[ -z "$input" ]]; then
        error_exit "$error_msg"
    fi
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root (use sudo)" 
fi

# === Configuration ===
echo "=== VPS Setup Script ==="

# Prompt for inputs with validation
echo "Enter database root password (min 8 characters):"
read -r -s DB_ROOT_PASSWORD
validate_input "$DB_ROOT_PASSWORD" "Database root password cannot be empty"

echo "Enter database user name:"
read -r DB_USER
validate_input "$DB_USER" "Database username cannot be empty"

echo "Enter database user password (min 8 characters):"
read -r -s DB_PASSWORD
validate_input "$DB_PASSWORD" "Database user password cannot be empty"

echo "Enter database name:"
read -r DB_NAME
validate_input "$DB_NAME" "Database name cannot be empty"

echo "Enter PHP version (e.g., 8.2):"
read -r PHP_VERSION
validate_input "$PHP_VERSION" "PHP version cannot be empty"

echo "Enter domain name for SSL (e.g., example.com):"
read -r DOMAIN_NAME
validate_input "$DOMAIN_NAME" "Domain name cannot be empty"

echo "Enter admin email for Let's Encrypt:"
read -r ADMIN_EMAIL
validate_input "$ADMIN_EMAIL" "Admin email cannot be empty"

echo "Enter Node.js version to install (e.g., 22, 20, 18):"
read -r NODE_VERSION
validate_input "$NODE_VERSION" "Node.js version cannot be empty"

# === System Update and Preparation ===
echo "[1/14] Updating system packages..."
apt update || error_exit "Failed to update packages"
apt upgrade -y || error_exit "Failed to upgrade packages"

# Install essential tools with error handling
echo "[2/14] Installing essential tools..."
apt install -y curl wget git vim ufw fail2ban htop unzip software-properties-common \
    || error_exit "Failed to install essential tools"

# === Security Hardening ===
## Firewall Setup
echo "[3/14] Configuring UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
yes | ufw enable || error_exit "Failed to configure UFW"

## Fail2Ban Setup with enhanced configuration
echo "[4/14] Configuring Fail2Ban..."
systemctl enable fail2ban --now
cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

# Advanced email notifications
destemail = ${ADMIN_EMAIL}
sender = root@$(hostname -f)
mta = sendmail

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOL
systemctl restart fail2ban || error_exit "Failed to restart Fail2Ban"

# === Install Nginx ===
echo "[5/14] Installing and configuring Nginx..."
apt install -y nginx || error_exit "Failed to install Nginx"
systemctl enable nginx --now

# === Install MariaDB ===
echo "[6/14] Installing MariaDB..."
apt install -y mariadb-server || error_exit "Failed to install MariaDB"
systemctl enable mariadb --now

# Secure MariaDB with improved security
echo "[6.1/14] Securing MariaDB..."
mysql_secure_installation <<EOF
n
${DB_ROOT_PASSWORD}
${DB_ROOT_PASSWORD}
y
y
y
y
EOF

# Create database and user with proper privileges
echo "[6.2/14] Setting up database..."
mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === Install PHP ===
echo "[7/14] Installing PHP ${PHP_VERSION}..."
add-apt-repository -y ppa:ondrej/php
apt update
apt install -y php"${PHP_VERSION}" php"${PHP_VERSION}"-fpm php"${PHP_VERSION}"-mysql \
    php"${PHP_VERSION}"-curl php"${PHP_VERSION}"-xml php"${PHP_VERSION}"-mbstring \
    || error_exit "Failed to install PHP"

systemctl enable php"${PHP_VERSION}"-fpm --now

# === Configure Nginx ===
echo "[8/14] Configuring Nginx for PHP..."
cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_comp_level 5;
    gzip_types text/plain application/xml text/css application/javascript image/x-icon image/svg+xml;
    gzip_disable "msie6";

    # Cache static files for 1 month
    location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
        expires 1M;
        add_header Cache-Control "public, no-transform";
    }
}
EOL

nginx -t || error_exit "Nginx configuration test failed"
systemctl reload nginx

# === Install Certbot for SSL ===
echo "[9/14] Installing Certbot..."
apt install -y certbot python3-certbot-nginx || error_exit "Failed to install Certbot"

# Request SSL certificates
echo "[10/14] Setting up SSL certificates..."
certbot --nginx -d "${DOMAIN_NAME}" -d www."${DOMAIN_NAME}" \
    --agree-tos --no-eff-email --email "${ADMIN_EMAIL}" \
    || error_exit "SSL certificate installation failed"

# === Optimize Nginx Performance ===
echo "[11/14] Optimizing Nginx performance..."
cat >> /etc/nginx/nginx.conf <<EOL
# Optimize Nginx Worker
worker_processes auto;
worker_rlimit_nofile 65535;
events {
    multi_accept on;
    worker_connections 65535;
}

http {
    # Additional performance tweaks
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
}
EOL

# === Install AppArmor ===
echo "[12/14] Installing and configuring AppArmor..."
apt install -y apparmor apparmor-utils || error_exit "Failed to install AppArmor"
systemctl enable apparmor --now
aa-status

echo "[13/14] Installing NVM and Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install ${NODE_VERSION}
npm install -g pm2

# Get installed versions
NODE_INSTALLED_VERSION=$(node -v)
NPM_INSTALLED_VERSION=$(npm -v)
PM2_INSTALLED=$(pm2)

# === Cleanup and Finish ===
echo "[14/14] Cleaning up..."
apt autoremove -y
apt autoclean -y

# === Summary ===
echo "====================================="
echo "✅ VPS Setup Complete!"
echo "====================================="
echo "Database Details:"
echo "- Name: ${DB_NAME}"
echo "- User: ${DB_USER}"
echo "- Domain: ${DOMAIN_NAME}"
echo "Node.js Version: ${NODE_INSTALLED_VERSION}"
echo "NPM Version: ${NPM_INSTALLED_VERSION}"
echo "====================================="
