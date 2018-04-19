#!/bin/bash

. ./vm2.config


echo "

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
#auto $EXTERNAL_IF
#iface $EXTERNAL_IF inet $EXT_IP

auto $INTERNAL_IF
iface $INTERNAL_IF inet static
 address $INT_IP
# netmask 255.255.255.0

auto $MANAGEMENT_IF
iface $MANAGEMENT_IF inet dhcp


auto $INTERNAL_IF.$VLAN
iface $INTERNAL_IF.$VLAN inet static
 address $VLAN_IP
# netmask 255.255.255.0
 vlan_raw_device $INTERNAL_IF


" > /etc/network/interfaces

service networking restart

ip route flush 0/0
route add default gw $GW_IP


apt-get update
apt-get install apache2

sed -i 's/80/8080/' /etc/apache2/ports.conf
sed -i 's/*:80/$APACHE_VLAN_IP:8080/' /etc/apache2/sites-available/000-default.conf

service apache2 restart

