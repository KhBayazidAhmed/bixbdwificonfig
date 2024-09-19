#!/bin/sh

# Define color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# Function to print colored messages
print_message() {
  COLOR=$1
  MESSAGE=$2
  echo -e "${COLOR}${MESSAGE}${RESET}"
}

# Function to check if a package is installed
check_and_install() {
  PACKAGE=$1
  if ! opkg list-installed | grep -q "^$PACKAGE"; then
    print_message $YELLOW "$PACKAGE is not installed. Installing..."
    opkg update
    opkg install "$PACKAGE"
  else
    print_message $GREEN "$PACKAGE is already installed."
  fi
}

# Check and install required packages
check_and_install nodogsplash
check_and_install xl2tpd
check_and_install curl
check_and_install unzip  

# Directory to download and extract the repository
TARGET_DIR="/root/bixbdwificonfig"
ZIP_FILE="/root/bixbdwificonfig.zip"
REPO_URL="https://github.com/KhBayazidAhmed/bixbdwificonfig/archive/refs/heads/main.zip"

# Remove the existing directory if it exists
if [ -d "$TARGET_DIR" ]; then
  print_message $YELLOW "Removing existing directory $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
fi

# Download and extract the repository
print_message $YELLOW "Downloading repository from $REPO_URL..."
curl -L "$REPO_URL" -o "$ZIP_FILE"

print_message $YELLOW "Extracting $ZIP_FILE..."
unzip "$ZIP_FILE" -d /root

# Rename the extracted directory to TARGET_DIR
if [ -d "/root/bixbdwificonfig-main" ]; then
  mv "/root/bixbdwificonfig-main" "$TARGET_DIR"
  rm "$ZIP_FILE"  # Clean up ZIP file
else
  print_message $RED "Failed to extract the ZIP file correctly."
  exit 1
fi

# Remove the curl package
print_message $YELLOW "Removing curl package..."
opkg remove curl
print_message $YELLOW "Removing unzip package..."
opkg remove unzip

# Define the source and destination paths
NDS_SOURCE_FILE="$TARGET_DIR/nodogsplash"
NDS_DESTINATION_DIR="/etc/config"
MYAUTH_SOURCE_FILE="$TARGET_DIR/myauth.sh"
MYAUTH_DESTINATION_DIR="/usr/lib/nodogsplash"
HTDOCS_SOURCE_DIR="$TARGET_DIR/htdocs"
HTDOCS_DESTINATION_DIR="/etc/nodogsplash/htdocs"
L2TP_SCRIPT="$TARGET_DIR/check_l2tp.sh"
L2TP_DESTINATION="/root/check_l2tp.sh"

# Move the nodogsplash file if it exists
if [ -f "$NDS_SOURCE_FILE" ]; then
  print_message $YELLOW "Moving nodogsplash file to $NDS_DESTINATION_DIR..."
  mv "$NDS_SOURCE_FILE" "$NDS_DESTINATION_DIR"
  print_message $GREEN "nodogsplash file moved successfully."
else
  print_message $RED "nodogsplash file not found in $TARGET_DIR."
fi

# Move the myauth.sh file and set executable permission
if [ -f "$MYAUTH_SOURCE_FILE" ]; then
  print_message $YELLOW "Moving myauth.sh to $MYAUTH_DESTINATION_DIR..."
  mv "$MYAUTH_SOURCE_FILE" "$MYAUTH_DESTINATION_DIR"
  chmod +x "$MYAUTH_DESTINATION_DIR/myauth.sh"
  print_message $GREEN "myauth.sh moved and permission set successfully."
else
  print_message $RED "myauth.sh file not found in $TARGET_DIR."
fi

# Replace the htdocs folder in /etc/nodogsplash
if [ -d "$HTDOCS_SOURCE_DIR" ]; then
  print_message $YELLOW "Replacing the htdocs folder in $HTDOCS_DESTINATION_DIR..."
  rm -rf "$HTDOCS_DESTINATION_DIR"
  mv "$HTDOCS_SOURCE_DIR" "/etc/nodogsplash/"
  print_message $GREEN "htdocs folder replaced successfully."

  # Update RouterName in splash.html
  SPLASH_FILE="/etc/nodogsplash/htdocs/splash.html"
  if [ -f "$SPLASH_FILE" ]; then
    print_message $YELLOW "Updating RouterName in $SPLASH_FILE..."
    sed -i 's/RouterName/biz/' "$SPLASH_FILE"
    print_message $GREEN "RouterName updated successfully."
  else
    print_message $RED "$SPLASH_FILE not found."
  fi
else
  print_message $RED "htdocs folder not found in $TARGET_DIR."
fi

# Move and set permissions for the L2TP monitoring script
if [ -f "$L2TP_SCRIPT" ]; then
  print_message $YELLOW "Moving check_l2tp.sh to $L2TP_DESTINATION..."
  mv "$L2TP_SCRIPT" "$L2TP_DESTINATION"
  chmod +x "$L2TP_DESTINATION"
  print_message $GREEN "check_l2tp.sh moved and permissions set successfully."
else
  print_message $RED "check_l2tp.sh file not found in $TARGET_DIR."
fi

# Set up a cron job to run the script every hour
CRON_JOB="0 * * * * /root/check_l2tp.sh"
CRON_FILE="/etc/crontabs/root"

# Create the cron file if it doesn't exist
if [ ! -f "$CRON_FILE" ]; then
  touch "$CRON_FILE"
  print_message $YELLOW "Created new cron file $CRON_FILE."
fi

# Add the cron job if it does not already exist
if ! grep -q "$CRON_JOB" "$CRON_FILE"; then
  print_message $YELLOW "Adding cron job to run check_l2tp.sh every hour..."
  echo "$CRON_JOB" >> "$CRON_FILE"
  /etc/init.d/cron reload
  print_message $GREEN "Cron job added and cron service reloaded."
else
  print_message $GREEN "Cron job already exists."
fi

# Cleanup: Remove the TARGET_DIR
if [ -d "$TARGET_DIR" ]; then
  print_message $YELLOW "Removing $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
  print_message $GREEN "$TARGET_DIR removed successfully."
else
  print_message $RED "$TARGET_DIR not found for removal."
fi

print_message $GREEN "Script completed."
