#!/bin/bash

# Function to display messages with formatting
print_message() {
    echo "**********************"
    echo "$1"
    echo "**********************"
}

# Function to configure the network
configure_network() {
    echo "Configuring the network..."
    cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      dhcp4: no
      addresses: [192.168.16.22/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF

    sudo netplan apply
}

# Call the function to configure the network
configure_network

# Function to update the /etc/hosts file
update_hosts() {
    print_message "Updating /etc/hosts File"
    local new_entry="192.168.16.21    server1"

    # Remove old entry if present
sudo grep -v '^192\.168\.16\.21[[:space:]]\+server1$' /etc/hosts | sudo tee /etc/hosts >/dev/null

    # Add new entry
    echo "$new_entry" | sudo tee -a /etc/hosts >/dev/null
}

# Update /etc/hosts file
update_hosts

# Function to display messages with formatting
print_message() {
    echo "**********************"
    echo "$1"
    echo "**********************"
}

# Function to install Apache2
install_apache() {
    print_message "Installing Apache2"
    sudo apt update
    sudo apt install -y apache2
}

# Function to install Squid
install_squid() {
    print_message "Installing Squid"
    sudo apt update
    sudo apt install -y squid
}

# Function to start and enable Apache2 service
start_apache() {
    print_message "Starting and Enabling Apache2 Service"
    sudo systemctl start apache2
    sudo systemctl enable apache2
}

# Function to start and enable Squid service
start_squid() {
    print_message "Starting and Enabling Squid Service"
    sudo systemctl start squid
    sudo systemctl enable squid
}


# Install Apache2
install_apache

# Start and enable Apache2 service
start_apache

# Install Squid
install_squid

# Start and enable Squid service
start_squid

# Function to enable UFW and configure firewall rules
configure_firewall() {
    print_message "Configuring Firewall with UFW"
    
    # Enable UFW
    sudo ufw enable

    # Allow SSH on port 22 only on the management network
    sudo ufw allow from <mgmt_network_ip> to any port 22

    # Allow HTTP on both interfaces
    sudo ufw allow http

    # Allow web proxy on both interfaces (assuming default Squid proxy port 3128)
    sudo ufw allow 3128

    # Reload UFW to apply changes
    sudo ufw reload
}


# Configure firewall rules using UFW
configure_firewall

# Function to display messages with formatting
print_message() {
    echo "**********************"
    echo "$1"
    echo "**********************"
}

# Function to create user accounts with specified configuration
create_users() {
    print_message "Creating User Accounts"

    # List of users to create
    local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    # Create users with home directory and bash shell
    for user in "${users[@]}"; do
        sudo useradd -m -s /bin/bash "$user"
        echo "User '$user' created."

        # Generate RSA and Ed25519 keys for the user
        sudo -u "$user" ssh-keygen -t rsa -N "" -f "/home/$user/.ssh/id_rsa"
        sudo -u "$user" ssh-keygen -t ed25519 -N "" -f "/home/$user/.ssh/id_ed25519"

        # Append RSA and Ed25519 public keys to authorized_keys file
        cat "/home/$user/.ssh/id_rsa.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null
        cat "/home/$user/.ssh/id_ed25519.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null

        echo "SSH keys generated and added for user '$user'."
    done
}

# Function to grant sudo access to dennis
grant_sudo_access() {
    print_message "Granting Sudo Access to Dennis"
    sudo usermod -aG sudo dennis
    echo "Sudo access granted to user 'dennis'."
}


# Create user accounts
create_users

# Grant sudo access to dennis
grant_sudo_access
