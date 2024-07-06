# Change-SSH-Port
Changes SSH port on Ubuntu machine with bash and checks if port is available first. Personal use, not good tool. 

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
- Checks if the new port is available.

### Creates a Backup of SSH Configuration:
- Backs up the current SSH configuration file to `/etc/ssh/sshd_config.bak`.

### Updates Firewall Rules:
- Checks if UFW (Uncomplicated Firewall) is installed and updates rules for the new port.
- Checks if iptables is installed and updates rules for the new port.
- Optionally keeps old firewall rules if the `--old-rules` flag is provided.

### Updates SSH Configuration:
- Modifies the `sshd_config` file to use the new SSH port.

### Restarts SSH Service:
- Restarts the SSH service to apply the new configuration.
- If the restart fails, restores the original configuration and restarts the service again.

