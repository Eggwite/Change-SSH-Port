# Change-SSH-Port
> ⚠️ **Warning:** This script has been hardly tested. Please proceed with caution.

Changes SSH port on Ubuntu, Debian, or CentOS machine with bash "semi-automatically". Please feel free to use it at your discretion.

User must be root:
```
sudo -i
```
Then copy and run:
```
bash <(curl -Ls https://raw.githubusercontent.com/Eggwite/Change-SSH-Port/main/change_ssh_port.sh)
```
Optionally, keep old firewall rules:
```
bash <(curl -Ls https://raw.githubusercontent.com/Eggwite/Change-SSH-Port/main/change_ssh_port.sh) --old-rules
```

## Here’s a summary of what the script does:

### Checks Linux Version Compatibility:
- Ensures the script is compatible with Ubuntu, Debian, or CentOS.
- Allows users to continue with an unsupported version if they choose.

### Gets Current SSH Port:
- Retrieves the current SSH port from the `sshd_config` file.
- Prompts the user for the current port if it can’t be found.

### Prompts for New SSH Port:
- Asks the user to enter a new SSH port.
- Check if the new port is available.

### Creates a Backup of SSH Configuration:
- Backs up the current SSH configuration file to `/etc/ssh/sshd_config.bak`.

### Updates Firewall Rules:
- Checks if UFW (Uncomplicated Firewall) is installed and updates rules for the new port, removing old port rules.
- Checks if iptables is installed and updates rules for the new port, removing old port rules.
- Optionally keeps old firewall rules if the `--old-rules` flag is provided.

### Updates SSH Configuration:
- Modifies the `sshd_config` file to use the new SSH port.

### Restarts SSH Service:
- Restart the SSH service to apply the new configuration.
- If the restart fails, restore the original configuration and restart the service.

# 💖 If you've read this far, why not give it a star? Maybe create a PR to improve my shoddy code.
