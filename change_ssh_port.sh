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

# Function to check Linux version compatibility
check_linux_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "centos" ]]; then
            return 0
        else
            echo -e "\e[31mThis script is only compatible with Ubuntu, Debian, and CentOS.\e[0m"
            read -p "Do you want to attempt to continue anyway? (yes/no) " choice
            choice=${choice:-no}
            if [[ "$choice" == "yes" ]]; then
                return 0
            else
                exit 1
            fi
        fi
    else
        echo -e "\e[31mCannot determine Linux distribution.\e[0m"
        read -p "Do you want to attempt to continue anyway? (yes/no) " choice
        choice=${choice:-no}
        if [[ "$choice" == "yes" ]]; then
            return 0
        else
            exit 1
        fi
    fi
}

# Check Linux version compatibility
check_linux_version

# Get the current SSH port from the sshd_config file
SSH_CONFIG="/etc/ssh/sshd_config"
if [[ ! -f "$SSH_CONFIG" ]]; then
    read -p "Cannot find sshd_config at $SSH_CONFIG. Please enter the correct path: " SSH_CONFIG
fi

OLD_PORT=$(grep "^Port " "$SSH_CONFIG" | awk '{print $2}')
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
BACKUP_PATH="/etc/ssh/sshd_config.bak"
echo "Creating a backup of the SSH configuration file at $BACKUP_PATH."
sudo cp "$SSH_CONFIG" "$BACKUP_PATH"

# Check if UFW is installed
if command_exists ufw; then
    echo "UFW is installed."
    if sudo ufw status | grep -q "$NEW_PORT"; then
        echo "UFW rule for port $NEW_PORT already exists."
    else
        echo "Adding UFW rule for port $NEW_PORT."
        sudo ufw allow $NEW_PORT/tcp
    fi
    if [[ "$1" == "--old-rules" ]]; then
        echo "Keeping UFW rule for old port $OLD_PORT."
    else
        echo "Deleting UFW rule for old port $OLD_PORT."
        sudo ufw delete allow $OLD_PORT/tcp
    fi
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
    if [[ "$1" == "--old-rules" ]]; then
        echo "Keeping iptables rule for old port $OLD_PORT."
    else
        echo "Deleting iptables rule for old port $OLD_PORT."
        sudo iptables -D INPUT -p tcp --dport $OLD_PORT -j ACCEPT
    fi

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
sudo sed -i "s/^Port $OLD_PORT/Port $NEW_PORT/" "$SSH_CONFIG"

# Restart SSH service to apply new configuration
echo "Restarting SSH service."
if sudo systemctl restart sshd; then
    echo -e "\e[32mThe SSH port has been changed to $NEW_PORT. Please try to SSH using the new port to confirm the successful change.\e[0m"
    echo -e "\e[32mBackup of the SSH configuration file is located at $BACKUP_PATH.\e[0m"
    exit 0
else
    sudo cp "$BACKUP_PATH" "$SSH_CONFIG"
    sudo systemctl restart sshd
    echo -e "\e[31mThe SSH port has not been changed.\e[0m"
    exit 1
fi

# Prompt user to press any key to finish
read -p "Press any key to finish..." -n1 -s
echo
