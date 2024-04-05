#!/bin/bash

log_changes() {
    [ "$VERBOSE" = true ] && echo "$1"
    logger "$1"
}

update_hostname() {
    local new_hostname="$1"
    current_hostname=$(hostname)
    
    if [ "$new_hostname" != "$current_hostname" ]; then
        sudo hostnamectl set-hostname "$new_hostname"
        log_changes "Hostname updated to $new_hostname"
        echo "Hostname updated to $new_hostname"
    else
        log_changes "Hostname is already set to $new_hostname"
    fi
}

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> /var/log/hostname_change.log
}

update_hostname "desired_hostname"

update_ip() {
    local new_ip="$1"
    if [ "$new_ip" != "$(hostname -I | awk '{print $1}')" ]; then
        sed -i "/^.*$(hostname -I | awk '{print $1}').*/c\\$new_ip $HOSTNAME" /etc/hosts
        sed -i "s/address .*/address $new_ip/g" /etc/netplan/*.yaml
        netplan apply
        log_changes "IP address updated to $new_ip"
    fi
}

update_host_entry() {
    local desired_name="$1"
    local desired_ip="$2"
    if grep -q "$desired_name" /etc/hosts; then
        log_changes "Host entry already exists for $desired_name with IP $desired_ip"
    else
        echo "$desired_ip    $desired_name" | sudo tee -a /etc/hosts >/dev/null
        log_changes "Host entry added for $desired_name with IP $desired_ip"
        echo "Host entry added for $desired_name with IP $desired_ip"
    fi
}

update_host_entry "desired_hostname" "desired_ip"

trap '' TERM HUP INT

if [ -n "$SYS_INFO" ]; then
    update_system_info
fi

if [ -n "$NET_INFO" ]; then
    update_network_info
fi

if [ -n "$HOST_ENTRY" ]; then
    update_hosts_info
fi

exit 0

