#!/bin/bash

NEW_IP=$(wget http://www.cpanel.net/showip.cgi -q -O -)

cp ./conf/default.db ./$1.db
echo "zone \"$1\" {type master; file \"/etc/bind/db/$1\";};" >> /etc/bind/named.conf
CHANGE_IP="perl -pi -e 's/_IP_/${NEW_IP}/g' ./$1.db"
eval $CHANGE_IP
mv $1.db /etc/bind/db/$1
