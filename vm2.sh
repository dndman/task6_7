cat << 'EOF' > /etc/network/interfaces

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ens3
iface ens3 inet dhcp

auto ens3.278
iface ens3.278 inet static
 address 200.0.0.2
 netmask 255.255.255.0
 vlan_raw_device ens3



EOF

service networking restart

