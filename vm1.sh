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

ADDR=`ip addr show $EXTERNAL_IF|grep " inet " |awk '{print $2}'`

echo "
[SAN]
 subjectAltName=IP:${ADDR}
" > /tmp/oneused


#герерация ключа
openssl genrsa -out /etc/ssl/certs/root-ca.key 2048

#генерация корневого сертификата
openssl req -x509 -new -key /etc/ssl/certs/root-ca.key -days 365 -out /etc/ssl/certs/root-ca.crt \
-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Student/CN=noob.studio"

#генерируем сертификат, подписанный нами же
openssl genrsa -out /etc/ssl/certs/selfCA.key 2048

#генерим запрос на сертификат
openssl req -new -newkey rsa:4096 -key /etc/ssl/certs/selfCA.key \
-out /etc/ssl/certs/web.csr \
-subj "/C=UA/ST=Kharkov/L=Kharkov/O=Student/CN=$(hostname -f)" \
-reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf /tmp/oneused)


#подписываем запрос на сертификат
openssl x509 -req -in /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/certs/root-ca.key \
-CAcreateserial -out /etc/ssl/certs/web.crt -days 100 -extensions SAN -extfile /tmp/oneused

cat /etc/ssl/certs/web.crt  /etc/ssl/certs/root-ca.crt > /etc/ssl/certs/$(hostname -f).crt


echo "
server {
    server_name $(hostname -f);
    listen 443 ssl;
    access_log /var/log/nginx/test.log;
    error_log /var/log/nginx/test.log;

     ssl_certificate     /etc/ssl/certs/$(hostname -f).crt;
     ssl_certificate_key /etc/ssl/certs/selfCA.key;
     ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
     ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass       http://$APACHE_VLAN_IP:80;
        proxy_set_header Host      $(hostname -f);
        proxy_set_header X-Real-IP $ADDR;
    }
}

" > /etc/nginx/sites-available/default
service nginx restart

