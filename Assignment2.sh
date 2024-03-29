#!/bin/bash


# Function to update network configuration using netplan
configure_network() {
    log "Configuring network..."

    # Modify the netplan configuration file with specific network settings
    cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF

    # Apply netplan changes
    sudo netplan apply
}

# Function to install required software and configure firewall
install_software() {
    log "Installing software and configuring firewall..."

    # Update package repository and install necessary software packages
    sudo apt update
    sudo apt install -y openssh-server apache2 squid

    # Configure SSH to allow key authentication and disable password authentication
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart ssh

    # Configure Apache to listen on specific IP addresses and ports
    sudo sed -i 's/Listen 80/Listen 192.168.16.21:80/' /etc/apache2/ports.conf
    sudo sed -i 's/<VirtualHost \*:80>/<VirtualHost 192.168.16.21:80>/' /etc/apache2/sites-available/000-default.conf
    sudo sed -i 's/Listen 443/Listen 192.168.16.21:443/' /etc/apache2/ports.conf
    sudo sed -i 's/<VirtualHost default:443>/<VirtualHost 192.168.16.21:443>/' /etc/apache2/sites-available/default-ssl.conf
    sudo systemctl restart apache2

    # Configure Squid web proxy on a specific IP address and port
    sudo sed -i 's/http_port 3128/http_port 192.168.16.21:3128/' /etc/squid/squid.conf
    sudo systemctl restart squid

    # Enable UFW and allow necessary services through the firewall
    sudo ufw enable
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 3128/tcp
}

# Function to create user accounts with SSH keys and sudo access
create_users() {
    log "Creating user accounts..."

    # Create users and configure SSH keys for each user
    local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            log "Creating user: $user"

            sudo useradd -m -s /bin/bash "$user" # Add a user with a specified username and default shell
            sudo mkdir -p "/home/$user/.ssh"
            sudo touch "/home/$user/.ssh/authorized_keys"
            sudo chown -R "$user:$user" "/home/$user/.ssh"

            # Add SSH public keys for users based on their usernames
            case "$user" in
                "dennis")
                    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo tee -a "/home/$user/.ssh/authorized_keys" >/dev/null
                    ;;
                *)
                    # For other users, add their public keys here (This part is left as a placeholder)
                    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCezTPysKYTPTnrdXzlSmlbPtjQDebgWwHmE1QfM7LIuCNuKQZprVkbe+wfX4J+Rgp5vN0KHaxW8w/aRgB4yl7B8kTvW84OKcS1EACoKGl9Jrwb" | sudo tee -a "/home/$user/.ssh/authorized_keys" >/dev/null
                    ;;
            esac
            log "SSH keys added for user: $user"
        else
            log "User '$user' already exists. Skipping creation."
        fi
    done

    # Grant sudo access to the 'dennis' user
    sudo usermod -aG sudo dennis
    log "Sudo access granted to user 'dennis'."
}

# Main function to execute the script
main() {
    configure_network
    install_software
    create_users
    log "Script execution completed successfully!" # Notifies about the successful completion of the script
}

# Execute the main function
main
