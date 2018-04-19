#!/bin/bash

. ./vm1.config

#cat << 'EOF' > /etc/network/interfaces
echo "

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $EXTERNAL_IF
iface $EXTERNAL_IF inet $EXT_IP

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

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

sysctl -p

iptables -t nat -A POSTROUTING -o ens3 -s 10.0.0.0/24 -j MASQUERADE


service networking restart

apt-get update
apt-get -y install nginx

#герерация ключа
openssl genrsa -out /etc/ssl/certs/root-ca.key 2048

#генерация корневого сертификата
openssl req -x509 -new -key /etc/ssl/certs/root-ca.key -days 365 -out /etc/ssl/certs/root-ca.crt \
-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Student/CN=noob.studio"

#генерируем сертификат, подписанный нами же
openssl genrsa -out /etc/ssl/certs/selfCA.key 2048

#генерим запрос на сертификат
openssl req -new -newkey rsa:4096 -key /etc/ssl/certs/selfCA.key \
-out /etc/ssl/certs/web.crt \
-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Student/CN=vm1"

#подписываем запрос на сертификат
openssl x509 -req -in /etc/ssl/certs/web.crt -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/certs/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt -days 100

touch /etc/nginx/conf.d/default.conf

