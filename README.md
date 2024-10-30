# Captive Portal Setup on OpenWRT

This guide provides a step-by-step process to create a captive portal on an OpenWRT router. Users will be able to select their access time from the login page, and specific websites can be whitelisted.

## Prerequisites

- An OpenWRT router with SSH access.
- Basic knowledge of command-line operations.

## Step 1: Install Required Packages

### 1.1 Connect to Your Router via SSH

```bash
ssh root@<router_ip>
```

### 1.2 Update the Package List

```bash
opkg update
```

### 1.3 Install uHTTPd and Cron

```bash
opkg install uhttpd cron
```

### 1.4 Install Required iptables Packages

```bash
opkg install iptables iptables-mod-tproxy iptables-mod-nat iptables-mod-conntrack-extra kmod-ipt-nat kmod-ipt-nat-extra
```

## Step 2: Configure uHTTPd

### 2.1 Edit the uHTTPd Configuration File

```bash
vi /etc/config/uhttpd
```

### 2.2 Set the Following Parameters

```plaintext
config uhttpd main
    list listen_http 0.0.0.0:80
    option document_root /www
    option home /www
    option index_page index.html
    option cgi_prefix /cgi-bin
    option cert /etc/uhttpd.crt
    option key /etc/uhttpd.key
```

## Step 3: Create the Captive Portal HTML Page

### 3.1 Create or Edit the `index.html ` File

```bash
vi /www/index.html
```

### 3.2 Add the Following HTML Code

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Login</title>
  </head>
  <body>
    <h1>Welcome to the Captive Portal</h1>
    <form action="/login" method="post">
      <label for="username">Username:</label><br />
      <input type="text" id="username" name="username" required /><br /><br />
      <label for="duration">Select Access Duration (in hours):</label><br />
      <select id="duration" name="duration">
        <option value="1">1 Hour</option>
        <option value="2">2 Hours</option>
        <option value="3">3 Hours</option>
        <option value="4">4 Hours</option></select
      ><br /><br />
      <input type="submit" value="Login" />
    </form>
  </body>
</html>
```

## Step 4: Create a CGI Script to Handle Login

### 4.1 Create the CGI Script

```bash
vi /www/cgi-bin/login.cgi
```

### 4.2 Add the Following Code to Handle User Login

```bash
#!/bin/sh
echo "Content-type: text/html"
echo ""

read -n 1000 POST*DATA
USERNAME=$(echo "$POST_DATA" | sed -n 's/^.\_username=$$[^&]*$$.*$/ 1/p' | sed 's/%20/ /g')
DURATION=$(echo "$POST_DATA" | sed -n 's/^.*duration=$$[^&]_$$._$/ 1/p')

# Convert duration from hours to seconds

DURATION_SECONDS=$((DURATION \* 3600))

# Get current timestamp and calculate expiry timestamp

CURRENT_TIME=$(date +%s)
EXPIRY_TIME=$((CURRENT_TIME + DURATION_SECONDS))

# Set iptables rules for this user (you might want to use unique identifiers)

iptables -A FORWARD -m state --state NEW -m owner --uid-owner $USERNAME -j ACCEPT
iptables -A INPUT -m state --state NEW -m owner --uid-owner $USERNAME -j ACCEPT

# Schedule removal of access after duration expires

(sleep $DURATION_SECONDS; iptables -D FORWARD -m state --state NEW -m owner --uid-owner $USERNAME; iptables -D INPUT -m state --state NEW -m owner --uid-owner $USERNAME) &

echo "<h1>Welcome, $USERNAME!</h1>"
echo "<p>You have been granted internet access for $DURATION hour(s).</p>"
```

### 4.3 Make the Script Executable

```bash
chmod +x /www/cgi-bin/login.cgi
```

## Step 5: Update uHTTPd Configuration for CGI

Ensure that `uHTTPd ` is configured to execute CGI scripts:

### 5.1 Edit `/etc/config/uhttpd `

Ensure it has:

```plaintext
option cgi_prefix /cgi-bin
```

## Step 6: Configure iptables for Whitelisting

### 6.1 Add Whitelist Rules

For example, if you want to whitelist `example.com `, resolve its IP address and add rules like this:

```bash
WHITELIST_IP=$(dig +short example.com)

# Allow traffic to whitelisted IPs (replace with actual IPs)

iptables -A FORWARD -p tcp -d $WHITELIST_IP --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d $WHITELIST_IP --dport 443 -j ACCEPT

# Allow DNS queries for whitelisted domains (adjust as necessary)

iptables -A INPUT -p udp --dport 53 -j ACCEPT
```

## Step 7: Start Services

### 7.1 Restart uHTTPd

```bash
/etc/init.d/uhttpd restart
```

### 7.2 Reboot Your Router (optional but recommended)

```bash
reboot
```

## Step 8: Test Your Captive Portal

### 8.1 Connect a Device

Connect a device to your Wi-Fi network.

### 8.2 Access the Captive Portal

Open a web browser and navigate to your router's IP address.

### 8.3 Select Access Duration

Fill out the form with a username and select an access duration, then submit.

### 8.4 Verify Access

Ensure that internet access is granted based on the selected duration.

## Optional Enhancements

- Consider implementing user session management for better control.
- Enhance security by validating user input in your CGI script.
- Implement logging of user activity for monitoring purposes.
