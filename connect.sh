#!/bin/bash

function check_requirement {
       command -v $1  >/dev/null 2>&1 || { echo >&2 "$1 is missing. Install it and try again. Aborting."; exit 1; }
}

check_requirement dnsmasq
check_requirement openconnect

echo "allow-hotplug eth0  
iface eth0 inet static  
    address 192.168.2.1
    netmask 255.255.255.0
    network 192.168.2.0
    broadcast 192.168.2.255" > /etc/network/interfaces.d/eth0

echo "interface=eth0
listen-address=192.168.2.1
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.2.2,192.168.2.100,12h" > /etc/dnsmasq.conf

sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/' /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

echo "Server: "
read server
echo "Group: "
read group
echo "Username: "
read user
echo "Password: "
stty -echo

#read password
charcount=0
while IFS= read -p "$prompt" -r -s -n 1 ch
do
    if [[ $ch == $'\0' ]] ; then
        break
    fi
    if [[ $ch == $'\177' ]] ; then
        if [ $charcount -gt 0 ] ; then
            charcount=$((charcount-1))
            prompt=$'\b \b'
            pass="${pass%?}"
        else
            PROMPT=''
        fi
    else
        charcount=$((charcount+1))
        prompt='*'
        pass+="$ch"
    fi
done

stty echo

echo $pass | sudo openconnect -u $user --authgroup $group --passwd-on-stdin $server
