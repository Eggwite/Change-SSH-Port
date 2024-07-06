#!/bin/bash

# Function to check if a port is in use
check_port() {
    if lsof -i -P -n | grep -q ":$1 "; then
        return 1
    else
        return 0
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get the current SSH port from the sshd_config file
OLD_PORT=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
if [ -z "$OLD_PORT" ]; then
    read -p "Enter the current SSH port (default is 22): " OLD_PORT
    OLD_PORT=${OLD_PORT:-22}
fi
echo "Current SSH port is $OLD_PORT."

# Prompt for new SSH port
read -p "Enter the new SSH port: " NEW_PORT

# Check if the new port is available
if check_port $NEW_PORT; then
    echo "Port $NEW_PORT is available."
else
    echo "Port $NEW_PORT is already in use by the following service(s):"
    lsof -i -P -n | grep ":$NEW_PORT "
    echo "Please handle the port conflict manually."
    exit 1
fi

# Create a backup of the SSH configuration file
echo "Creating a backup of the SSH configuration file."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Check if UFW is installed
if command_exists ufw; then
    echo "UFW is installed."
    if sudo ufw status | grep -q "$NEW_PORT"; then
        echo "UFW rule for port $NEW_PORT already exists."
    else
        echo "Adding UFW rule for port $NEW_PORT."
        sudo ufw allow $NEW_PORT/tcp
    fi
    echo "Deleting UFW rule for old port $OLD_PORT."
    sudo ufw delete allow $OLD_PORT/tcp
else
    echo "UFW is not installed."
fi

# Check if iptables is installed
if command_exists iptables; then
    echo "iptables is installed."
    if sudo iptables -C INPUT -p tcp --dport $NEW_PORT -j ACCEPT 2>/dev/null; then
        echo "iptables rule for port $NEW_PORT already exists."
    else
        echo "Adding iptables rule for port $NEW_PORT."
        sudo iptables -A INPUT -p tcp --dport $NEW_PORT -j ACCEPT
    fi
    echo "Deleting iptables rule for old port $OLD_PORT."
    sudo iptables -D INPUT -p tcp --dport $OLD_PORT -j ACCEPT

    # Check if iptables-persistent is installed
    if command_exists iptables-save && [ -f /etc/iptables/rules.v4 ]; then
        echo "Saving iptables rules."
        sudo iptables-save > /etc/iptables/rules.v4
    else
        echo "iptables-persistent is not installed. Please manage iptables rules manually."
    fi
else
    echo "iptables is not installed."
fi

# Update SSH configuration
echo "Updating SSH configuration."
sudo sed -i "s/^Port $OLD_PORT/Port $NEW_PORT/" /etc/ssh/sshd_config

# Restart SSH service to apply new configuration
echo "Restarting SSH service."
sudo systemctl restart sshd

echo "SSH port changed from $OLD_PORT to $NEW_PORT and firewall rules updated."

# Prompt user to press any key to finish
read -p "Press any key to finish..." -n1 -s
echo
