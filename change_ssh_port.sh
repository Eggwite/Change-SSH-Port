#!/bin/bash

# Define old SSH port
OLD_PORT=22

# Function to check if a port is in use
check_port() {
    if lsof -i -P -n | grep -q ":$1 "; then
        return 1
    else
        return 0
    fi
}

# Prompt for new SSH port
read -p "Enter the new SSH port: " NEW_PORT

# Check if the new port is available
while ! check_port $NEW_PORT; do
    echo "Port $NEW_PORT is already in use. Please choose another port."
    read -p "Enter the new SSH port: " NEW_PORT
done

# Update SSH configuration
sed -i "s/#Port $OLD_PORT/Port $NEW_PORT/" /etc/ssh/sshd_config

# Restart SSH service to apply new configuration
service sshd restart

# Update UFW rules
ufw delete allow $OLD_PORT
ufw allow $NEW_PORT

# Update iptables rules
iptables -D INPUT -p tcp --dport $OLD_PORT -j ACCEPT
iptables -A INPUT -p tcp --dport $NEW_PORT -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

echo "SSH port changed from $OLD_PORT to $NEW_PORT and firewall rules updated."
