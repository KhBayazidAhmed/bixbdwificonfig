#!/bin/sh

LOGFILE="/var/log/nodogsplash_auth.log"
USER_DEVICE_FILE="/var/run/user_device_map.txt"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

METHOD="$1"
MAC="$2"
USERNAME="$3"
PASSWORD="$4"

log_message "Method: $METHOD, MAC: $MAC, Username: $USERNAME, Password: $PASSWORD"

case "$METHOD" in
  auth_client)


    # Convert the password to an integer representing the authentication duration
    AUTH_TIME=$(echo "$PASSWORD" | awk '{print int($1)}')

    if [ -z "$AUTH_TIME" ] || [ "$AUTH_TIME" -le 0 ]; then
      AUTH_TIME=3600  # Default to 1 hour if password is not a valid number
    fi

    # Allow client to access the Internet for the specified time
    log_message "Authentication successful for $USERNAME with password duration: $AUTH_TIME seconds"
    echo "$AUTH_TIME 0 0"  # Allow access for the specified time with no upload/download limits

    # Record the device usage
    echo "$MAC $USERNAME" >> "$USER_DEVICE_FILE"
    log_message "Device $MAC associated with user $USERNAME."
    exit 0
    ;;

  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INCOMING_BYTES="$3"
    OUTGOING_BYTES="$4"
    SESSION_START="$5"
    SESSION_END="$6"

    # Convert session timestamps from nanoseconds to seconds
    SESSION_START_S=$(echo "$SESSION_START" | awk '{print int($1 / 1000000000)}')
    SESSION_END_S=$(echo "$SESSION_END" | awk '{print int($1 / 1000000000)}')

    # Log deauthentication information
    log_message "$METHOD: Incoming bytes: $INCOMING_BYTES, Outgoing bytes: $OUTGOING_BYTES, Session start: $(date -d @$SESSION_START_S), Session end: $(date -d @$SESSION_END_S)"

    # Remove the MAC address from the tracking file upon deauthentication
    if [ "$METHOD" = "client_deauth" ] || [ "$METHOD" = "idle_deauth" ] || [ "$METHOD" = "timeout_deauth" ] || [ "$METHOD" = "shutdown_deauth" ]; then
      sed -i "/^$MAC /d" "$USER_DEVICE_FILE"
      log_message "Deauthentication: MAC address $MAC removed from tracking file."
    fi
    ;;
  
  *)
    # Handle unsupported methods
    log_message "Unsupported METHOD: $METHOD"
    exit 1
    ;;
esac
