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


#finding the ip address
PUBLIC_IP=$(curl -s ip.webdade.com | jq -r '.ipv4')


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





# Create the SNIProxy configuration file
echo -e "${GREEN}Creating /etc/sniproxy.conf.${NC}"
cat <<EOF > /etc/sniproxy.conf
user daemon

pidfile /var/run/sniproxy.pid

#resolver {
#        nameserver 1.1.1.1
#       nameserver 8.8.8.8
#      mode ipv4_only
#}

listen 80 {
    proto http
    table http_hosts
}

listener 443 {
        proto tls
        table https_hosts
}

table http_hosts {
    .* *:80
}

table https_hosts {
    .* *:443
}
EOF
echo -e "${GREEN}SNIProxy configuration file created.${NC}"




# Install SNIProxy
DEB_PACKAGE=$(ls ../sniproxy_*.deb | head -n 1)
echo -e "${GREEN}Installing SNIProxy package: $DEB_PACKAGE${NC}"
dpkg -i "$DEB_PACKAGE"
echo -e "${GREEN}SNIProxy installed successfully.${NC}"



# Uncomment the DAEMON_ARGS line
CONFIG_FILE="/etc/default/sniproxy"
sed -i 's/^#DAEMON_ARGS="-c \/etc\/sniproxy.conf"/DAEMON_ARGS="-c \/etc\/sniproxy.conf"/' "$CONFIG_FILE"

# Change ENABLED to 1
sed -i 's/^ENABLED=0/ENABLED=1/' "$CONFIG_FILE"

echo "Updated $CONFIG_FILE:"
cat "$CONFIG_FILE"



# Install and configure dnsmasq
echo -e "${GREEN}Installing dnsmasq.${NC}"
apt-get install -y dnsmasq
echo -e "${GREEN}dnsmasq installed.${NC}"

echo -e "${GREEN}Creating /etc/dnsmasq.conf.${NC}"
cat <<EOF > /etc/dnsmasq.conf
domain-needed
bogus-priv
#no-resolv
no-poll
all-servers
server=1.1.1.1
server=8.8.8.8
#server=208.67.222.222
#server=2001:4860:4860::8888
#server=2001:4860:4860::8844
interface=eth0
listen-address=$PUBLIC_IP
address=/#/$PUBLIC_IP
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

# Enable and start services
echo -e "${GREEN}Enabling and starting services.${NC}"
systemctl enable sniproxy
systemctl enable dnsmasq

systemctl restart sniproxy
systemctl start dnsmasq
echo -e "${GREEN}Services enabled and started.${NC}"

# Create dnsmasq configuration for SNI
if [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${GREEN}Creating /etc/dnsmasq.d/sni.conf with public IP $PUBLIC_IP.                                                                                                                                                                                                                                             ${NC}"
    cat <<EOF > /etc/dnsmasq.d/dnsmasq.conf
address=/#/$PUBLIC_IP
domain-needed
bogus-priv
no-resolv
no-poll
all-servers
server=1.1.1.1
server=8.8.8.8
#server=208.67.222.222
#server=2001:4860:4860::8888
#server=2001:4860:4860::8844
interface=eth0
listen-address=$PUBLIC_IP
address=/#/$PUBLIC_IP
EOF
    echo -e "${GREEN}DNSMasq configuration for SNI created.${NC}"
else
    echo -e "${RED}Invalid IP detected. Please configure /etc/dnsmasq.d/sni.conf                                                                                                                                                                                                                                              manually.${NC}"
fi


echo -e "${GREEN}Creating /etc/dnsmasq.conf.${NC}"
cat <<EOF > /run/dnsmasq/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

cat <<EOF > /run/dnsmasq/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf

systemctl restart systemd-resolved
systemctl enable systemd-resolved


systemctl restart dnsmasq.service


echo -e "${YELLOW}To use this setup, configure your DNS settings on the desired                                                                                                                                                                                                                                              server that has no access to the desired domain. For example, in Linux, add the                                                                                                                                                                                                                                              following line to /etc/hosts:${NC}"
echo -e "${GREEN}$PUBLIC_IP yourdesired.domain.com${NC}"

echo -e "${YELLOW}Replace 'yourdesired.domain.com' with the domain you want to b                                                                                                                                                                                                                                             ypass.${NC}"
echo -e "${GREEN}- Installation completed successfully ...${NC}"
