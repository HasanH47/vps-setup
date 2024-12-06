#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# === Configuration ===
echo "Enter database root password:"
read -s DB_ROOT_PASSWORD
echo "Enter database user name:"
read DB_USER
echo "Enter database user password:"
read -s DB_PASSWORD
echo "Enter database name:"
read DB_NAME

echo "Enter PHP version:"
read PHP_VERSION

# === Update and Install Base Packages ===
echo "[1/12] Updating system packages..."
apt update && apt upgrade -y

# Install essential tools
echo "[2/12] Installing essential tools..."
apt install -y curl wget git vim ufw fail2ban htop unzip software-properties-common

# === Security Hardening ===
## Firewall Setup
echo "[3/12] Configuring UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

## Fail2Ban Setup
echo "[4/12] Configuring Fail2Ban..."
systemctl enable fail2ban --now
cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

destemail = root@localhost
sender = root@$(hostname -f)
mta = sendmail

[sshd]
enabled = true
EOL
systemctl restart fail2ban

# === Install Nginx ===
echo "[5/12] Installing and configuring Nginx..."
apt install -y nginx
systemctl enable nginx --now

# === Install MariaDB ===
echo "[6/12] Installing MariaDB..."
apt install -y mariadb-server
systemctl enable mariadb --now

# Secure MariaDB
echo "[6.1/12] Securing MariaDB..."
mysql_secure_installation <<EOF
n
${DB_ROOT_PASSWORD}
${DB_ROOT_PASSWORD}
y
y
y
y
EOF

# Create database and user
echo "[6.2/12] Setting up database..."
mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === Install PHP ===
echo "[7/12] Installing PHP ${PHP_VERSION}..."
add-apt-repository -y ppa:ondrej/php
apt update
apt install -y php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql

# Configure PHP
systemctl enable php${PHP_VERSION}-fpm --now

# === Configure Nginx ===
echo "[8/12] Configuring Nginx for PHP..."
cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    server_name _;

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
    gzip_types text/plain application/xml text/css application/javascript image/x-icon image/svg+xml;
    gzip_disable "msie6";

    # Cache static files for 1 month
    location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
        expires 1M;
        add_header Cache-Control "public, no-transform";
    }
}
EOL

nginx -t && systemctl reload nginx

# === Install Certbot for SSL ===
echo "[9/12] Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# Request SSL certificates
echo "[10/12] Setting up SSL certificates..."
certbot --nginx -d yourdomain.com --agree-tos --no-eff-email --email your-email@example.com

# === Optimize Nginx ===
echo "[11/12] Optimizing Nginx performance..."
# Add further optimizations to Nginx configuration
cat >> /etc/nginx/nginx.conf <<EOL

# Optimize Nginx Worker
worker_processes auto;
worker_connections 1024;

# Enable HTTP/2 for faster connections
server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...';  # Update the ciphers
    ssl_protocols TLSv1.2 TLSv1.3;
}
EOL

# === Install AppArmor ===
echo "[12/12] Installing and configuring AppArmor..."
apt install -y apparmor apparmor-utils
systemctl enable apparmor --now
aa-status

# === Cleanup and Finish ===
echo "[13/12] Cleaning up..."
apt autoremove -y && apt autoclean -y

# === Summary ===
echo "[14/12] Setup complete!"
echo "====================================="
echo "VPS is ready with the following details:"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Password: ${DB_PASSWORD}"
echo "Root Password: ${DB_ROOT_PASSWORD}"
echo "PHP Version: ${PHP_VERSION}"
echo "====================================="
