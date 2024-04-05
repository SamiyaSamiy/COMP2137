log_changes() {
    [ "$VERBOSE" = true ] && echo "$1"
    logger "$1"
}

update_hostname() {
    local desired_name="$1"
    if [ "$desired_name" != "$(hostname)" ]; then
        hostnamectl set-hostname "$desired_name"
        sed -i "s/$(hostname)/$desired_name/g" /etc/hosts
        echo "$desired_name" > /etc/hostname
        log_changes "Hostname updated to $desired_name"
    fi
}

update_ip() {
    local desired_ip="$1"
    if [ "$desired_ip" != "$(hostname -I | awk '{print $1}')" ]; then
        sed -i "/^.*$(hostname -I | awk '{print $1}').*/c\\$desired_ip $HOSTNAME" /etc/hosts
        sed -i "s/address .*/address $desired_ip/g" /etc/netplan/*.yaml
        netplan apply
        log_changes "IP address updated to $desired_ip"
    fi
}

update_host_entry() {
    local desired_name="$1"
    local desired_ip="$2"
    if ! grep -q "$desired_name" /etc/hosts; then
        echo "$desired_ip $desired_name" >> /etc/hosts
        log_changes "Added $desired_name with IP $desired_ip to /etc/hosts"
    fi
}

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
