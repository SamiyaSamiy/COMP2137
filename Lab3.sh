#!/bin/bash
# function to execute a command and check if it succeeded
execute_command() {
    if ! "$@"; then
        echo "Error executing: $@"
        exit 1
    fi
}

verbose_flag=""

# Check if the script is in verbose mode
if [ "$1" = "-v" ]; then
    verbose_flag="-v"
fi


scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -verbose -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

# Transfer configure-host.sh to server2-mgmt and execute
scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -verbose -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

# Update local /etc/hosts
./configure-host.sh -verbose -hostentry loghost 192.168.16.3
./configure-host.sh -verbose -hostentry webhost 192.168.16.4
