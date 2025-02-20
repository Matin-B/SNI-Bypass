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

## رفع محدودیت درگاه‌های پرداخت ایرانی
از **اوایل مهر 1403**، شرکت **شاپرک** محدودیت‌هایی روی درگاه‌های پرداختی که هاست آنها در خارج از ایران قرار دارد اعمال کرده است. این موضوع باعث شده کاربران خارج از کشور در اتصال به این درگاه‌ها دچار مشکل شوند.  

اگر نیاز دارید این محدودیت را دور بزنید و درگاه‌های بانکی ایرانی را از سرورهای خارج از کشور در دسترس داشته باشید، می‌توانید از این پروژه همراه با فایل **hosts** زیر استفاده کنید.

### نمونه تنظیمات `/etc/hosts`  
**لطفاً `SNI_SERVER_IP` را با آی‌پی سرور SNI-Bypass خود جایگزین کنید.**  

```bash
SNI_SERVER_IP        pep.shaparak.ir
SNI_SERVER_IP        sep.shaparak.ir
SNI_SERVER_IP        pna.shaparak.ir
SNI_SERVER_IP        pec.shaparak.ir
SNI_SERVER_IP        sadad.shaparak.ir
SNI_SERVER_IP        fcp.shaparak.ir
SNI_SERVER_IP        sepehr.shaparak.ir
SNI_SERVER_IP        ikc.shaparak.ir
SNI_SERVER_IP        bpm.shaparak.ir
SNI_SERVER_IP        ecd.shaparak.ir
SNI_SERVER_IP        asan.shaparak.ir
```

### نحوه استفاده از این پروژه  
برای آموزش کامل راه‌اندازی و استفاده از این پروژه جهت رفع مشکل ایران اکسس درگاه های پرداخت، به لینک زیر مراجعه کنید:  
https://webdade.com/blog/iran-access-and-non-connection-of-payment-gateway

### Special thanks to Saeed Yavari with this [article](https://behineserver.com/blog/dedicate-anti-sanctions)
