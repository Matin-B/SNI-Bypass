#!/bin/bash

# SNI Bypass Installer for Ubuntu 24

LOGFILE="/var/log/sni-bypass-install.log"

exec > >(tee -a ${LOGFILE}) 2>&1

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}- Installation started ...${NC}\n"

# Update system packages
echo -e "${GREEN}Updating system packages.${NC}"
apt-get update -y
apt-get upgrade -y
echo -e "${GREEN}System update completed.${NC}"

# Install jq for JSON parsing
echo -e "${GREEN}Installing jq.${NC}"
apt-get install -y jq
echo -e "${GREEN}jq installed successfully.${NC}"

# Install prerequisites
echo -e "${GREEN}Installing prerequisites.${NC}"
apt-get install -y autotools-dev cdbs debhelper dh-autoreconf dpkg-dev gettext libev-dev libpcre2-dev libudns-dev pkg-config fakeroot devscripts net-tools
echo -e "${GREEN}Prerequisites installed.${NC}"

# Clone the SNIProxy repository
echo -e "${GREEN}Cloning SNIProxy repository.${NC}"
git clone https://github.com/dlundquist/sniproxy.git
cd sniproxy

# Prompt user for DEBEMAIL and DEBFULLNAME
read -p "Enter your email address for DEBEMAIL: " DEBEMAIL
read -p "Enter your full name for DEBFULLNAME: " DEBFULLNAME
export DEBEMAIL
export DEBFULLNAME

echo -e "${GREEN}Building SNIProxy.${NC}"
./autogen.sh && dpkg-buildpackage -us -uc
echo -e "${GREEN}SNIProxy built successfully.${NC}"

# Install SNIProxy
DEB_PACKAGE=$(ls ../sniproxy_*.deb | head -n 1)
echo -e "${GREEN}Installing SNIProxy package: $DEB_PACKAGE${NC}"
dpkg -i "$DEB_PACKAGE"
echo -e "${GREEN}SNIProxy installed successfully.${NC}"

# Create the SNIProxy configuration file
echo -e "${GREEN}Creating /etc/sniproxy.conf.${NC}"
cat <<EOF > /etc/sniproxy.conf
user daemon

pidfile /var/run/sniproxy.pid

resolver {
        nameserver 1.1.1.1
        nameserver 8.8.8.8
        mode ipv4_only
}

#listener 80 {
#       proto http
#}

listener 443 {
        proto tls
}

table {
        .* *
}
EOF
echo -e "${GREEN}SNIProxy configuration file created.${NC}"

# Create the SNIProxy service file
echo -e "${GREEN}Creating /usr/lib/systemd/system/sniproxy.service.${NC}"
cat <<EOF > /usr/lib/systemd/system/sniproxy.service
[Unit]
Description=SNI Proxy Service
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/sniproxy -c /etc/sniproxy.conf

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}SNIProxy service file created.${NC}"

# Install and configure dnsmasq
echo -e "${GREEN}Installing dnsmasq.${NC}"
apt-get install -y dnsmasq
echo -e "${GREEN}dnsmasq installed.${NC}"

echo -e "${GREEN}Creating /etc/dnsmasq.conf.${NC}"
cat <<EOF > /etc/dnsmasq.conf
conf-dir=/etc/dnsmasq.d/,*.conf
cache-size=100000
no-resolv
server=1.1.1.1
server=8.8.8.8
interface=eth0
interface=lo
EOF
echo -e "${GREEN}dnsmasq configuration file created.${NC}"

# Handle potential conflicts with systemd-resolved and bind9
echo -e "${YELLOW}Checking for conflicts with systemd-resolved and bind9.${NC}"

if systemctl is-active --quiet systemd-resolved; then
    echo -e "${YELLOW}Stopping and disabling systemd-resolved.${NC}"
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
    unlink /etc/resolv.conf
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi

if systemctl is-active --quiet bind9; then
    echo -e "${YELLOW}Stopping and disabling bind9.${NC}"
    systemctl stop bind9
    systemctl disable bind9
fi

# Reload systemd and start dnsmasq
echo -e "${GREEN}Reloading systemd and starting dnsmasq.${NC}"
systemctl daemon-reload
systemctl start dnsmasq
echo -e "${GREEN}dnsmasq started.${NC}"

# Install and configure NGINX
echo -e "${GREEN}Installing NGINX.${NC}"
apt-get install -y nginx
echo -e "${GREEN}NGINX installed.${NC}"

echo -e "${GREEN}Backing up the default NGINX configuration.${NC}"
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

echo -e "${GREEN}Creating /etc/nginx/nginx.conf.${NC}"
cat <<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include             /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
        include /etc/nginx/default.d/*.conf;

        location / {
            rewrite ^ \$http_x_forwarded_proto://\$host\$request_uri permanent;
        }

        error_page 404 /404.html;
        location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
EOF
echo -e "${GREEN}NGINX configuration file created.${NC}"

# Check NGINX configuration and restart NGINX
echo -e "${GREEN}Checking NGINX configuration.${NC}"
nginx -t
echo -e "${GREEN}Reloading and restarting NGINX.${NC}"
systemctl reload nginx
systemctl restart nginx
echo -e "${GREEN}NGINX reloaded and restarted.${NC}"

# Enable and start services
echo -e "${GREEN}Enabling and starting services.${NC}"
systemctl enable sniproxy
systemctl enable dnsmasq
systemctl enable nginx

systemctl start sniproxy
systemctl start dnsmasq
systemctl start nginx
echo -e "${GREEN}Services enabled and started.${NC}"

# Create dnsmasq configuration for SNI
PUBLIC_IP=$(curl -s ip.webdade.com | jq -r '.ipv4')
if [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${GREEN}Creating /etc/dnsmasq.d/sni.conf with public IP $PUBLIC_IP.${NC}"
    cat <<EOF > /etc/dnsmasq.d/sni.conf
address=/#/$PUBLIC_IP
EOF
    echo -e "${GREEN}DNSMasq configuration for SNI created.${NC}"
else
    echo -e "${RED}Invalid IP detected. Please configure /etc/dnsmasq.d/sni.conf manually.${NC}"
fi

echo -e "${YELLOW}To use this setup, configure your DNS settings on the desired server that has no access to the desired domain. For example, in Linux, add the following line to /etc/hosts:${NC}"
echo -e "${GREEN}$PUBLIC_IP yourdesired.domain.com${NC}"

echo -e "${YELLOW}Replace 'yourdesired.domain.com' with the domain you want to bypass.${NC}"
echo -e "${GREEN}- Installation completed successfully ...${NC}"
