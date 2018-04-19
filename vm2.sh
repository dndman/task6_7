#!/bin/bash

. ./vm2.config

#cat << 'EOF' > /etc/network/interfaces
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

#EOF


