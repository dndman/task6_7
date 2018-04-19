#!/bin/bash


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

auto ens9
iface ens9 inet dhcp
# address 10.0.0.1
# netmask 255.255.255.0

auto ens9.278
iface ens9.278 inet static
 address 200.0.0.1
 netmask 255.255.255.0
 vlan_raw_device ens9


EOF

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1' /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o ens3 -s 10.0.0.0/24 -j MASQUERADE


service networking restart

Apt-get update
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
out -/etc/ssl/vm1.crt \
-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Student/CN=vm1"

#подписываем запрос на сертификат
openssl x509 -req -in /etc/ssl/vm1.csr -CA /etc/ssl/certs/root-ca.crt -CA /etc/ssl/certs/root-ca.key -Cacreateseial -out /etc/ssl/vm1.crt -days 100

