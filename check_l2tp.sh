#!/bin/sh

# Replace 'l2tp-SSH' with your actual L2TP interface name

INTERFACE="SSH"
LOGFILE="/root/l2tp_status.log"

# Get the current date and time
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Check if the interface is up and has an IP address
if ifstatus $INTERFACE | grep -q '"up": true' && ifstatus $INTERFACE | grep -q '"address":'; then
    echo "$TIMESTAMP: $INTERFACE is connected." >> $LOGFILE
else
    echo "$TIMESTAMP: $INTERFACE is not connected. Restarting..." >> $LOGFILE
    ifdown $INTERFACE
    sleep 5
    ifup $INTERFACE
    echo "$TIMESTAMP: $INTERFACE has been restarted." >> $LOGFILE
fi

# Keep only the last 10 log entries
tail -n 10 $LOGFILE > /tmp/l2tp_status.log && mv /tmp/l2tp_status.log $LOGFILE

