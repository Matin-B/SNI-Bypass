# SNI-Bypass
An automated setup script for configuring SNI Proxy, DNSMasq, and NGINX on Ubuntu 24 to bypass censorship and access restricted content.

## Features

- Automatic installation and configuration of SNI Proxy, DNSMasq, and NGINX.
- Customizable DNS resolution and redirection.
- Easy setup for bypassing network restrictions.

## Requirements
- Ubuntu 24

## Installation

1. **Clone the Repository**
    ```bash
    git clone https://github.com/Matin-B/SNI-Bypass.git
    cd SNI-Bypass
    ```
2. **Make the Installer Executable:**
    ```bash
    chmod +x sni-bypass-installer.sh
    ```
3. **Run the Installer:**
    ```bash
    sudo ./sni-bypass-installer.sh
    ```

## Post-Installation Configuration

After the installation, you need to configure the DNS settings on the desired server that doesn't have access to specific domains. For example, on a Linux server, you would add the following line to /etc/hosts:</br>
```bash
SNI_SERVER_IP <SPECIFIC_DOMAIN>
```
**Note: Replace `SNI_SERVER_IP` and `<domain>` with the detected public IP and the desired domain.**

If you want to bypass all domains using DNS, set /etc/dnsmasq.d/sni.conf as follows:
```bash
address=/#/SNI_SERVER_IP
```

If you want to bypass specific domains, specify them in /etc/dnsmasq.d/sni.conf and update /etc/hosts accordingly:
```bash
address=/<SPECIFIC_DOMAIN>/SNI_SERVER_IP
```


### Special thanks to Saeed Yavari with this [article](https://behineserver.com/blog/dedicate-anti-sanctions)
