#!/bin/bash
#
# Installer:
#	1.dovecot
#	2.exim
#	3.nginx
#	4.spamassassin
#	5.nginx
# Required:
#	1.Debian 7 - 32 bit.
#

# Am I root ?

if [ "x$(id -u)" != 'x0' ];
then
	echo "Error, can only be executed by root"
	exit 1
fi

VERSION="0.1-BETA"
SOFTWARE="nginx-full exim4 exim4-daemon-heavy dovecot-imapd dovecot-pop3d spamassassin"

HELP() {
	echo -en "\n\n\t!! WARNING !! \t\t***\t\t !! WARNING !!\n\n"
	echo "* Please kept private this code."
	echo "* This was written solely for educational purposes."
	echo "* Use it at your own risk."
	echo -en "* The author will be not responsible for any damage.\n\n"
	exit 1
}

VERSION() {
	echo "Author: ZmEu"
	echo "Contact: a AT foonet DOT org"
	echo "Name: installer-neds.sh"
	echo "Description: NOT FOUND"
	echo "License: PUBLIC"
	echo "Homepage: https://foonet.org"
	exit 1
}

PASS() {
	MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_+~!@#$%^&*()-="
	LENGTH="18"
	while [ ${n:=1} -le $LENGTH ]
	do
		PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
		let n+=1
	done
	echo "$PASS"
}

while getopts "vh" Option
do
	case $Option in
		v) VERSION ;;
		h) HELP ;;
		*) HELP ;;
	esac
done

apt-get -f install $SOFTWARE
service apache2 stop
service nginx stop
service bind9 stop
service exim4 stop
service postfix stop
service dovecot stop
service spamassassin stop
service mysql stop

# Backup exim, dovecot, bind
mkdir -p backup/{exim,dovecot,bind,nginx}
cp -rp /etc/exim4/* backup/exim
cp -rp /etc/dovecot/* backup/dovecot
cp -rp /etc/bind/* backup/bind
cp -rp /etc/nginx/* backup/nginx

# Remove data..
rm -rf /etc/exim4/dnsbl.conf /etc/exim4/exim4.conf.template /etc/exim4/spam-blocks.conf /etc/exim4/white-blocks.conf /etc/exim4/send_limits.conf
rm -rf /etc/dovecot/conf.d /etc/dovecot/dovecot.conf /etc/dovecot/ssl
rm -rf /etc/nginx/domains /etc/nginx/nginx.conf /etc/nginx/conf.d

# Generate SSL for Dovecot
mkdir -p /etc/dovecot/ssl
rm -rf /etc/dovecot/ssl/*
cp conf/foonet.org.pem /etc/dovecot/ssl/certificate.pem
cp conf/foonet.org.key /etc/dovecot/ssl/certificate.key
cp conf/foonet.org.ca /etc/dovecot/ssl/certificate.ca
#openssl genrsa -out /etc/dovecot/ssl/certificate.key 1024
#openssl req -new -x509 -key /etc/dovecot/ssl/certificate.key -out /etc/dovecot/ssl/certificate.pem -days 730
openssl dhparam -out /etc/dovecot/ssl/dhparam.pem 1024
openssl gendh >> /etc/dovecot/ssl/dhparam.pem

# Bind configuration
rm -rf /etc/bind/db
cp conf/named.conf /etc/bind
mkdir -p /etc/bind/db
cp conf/foonet.org.db /etc/bind/db/foonet.org
for i in `cat conf/domains`
do
	./bin/add_bind.sh $i
done
chown -R root:bind /etc/bind
chmod 640 /etc/bind/named.conf
update-rc.d bind9 defaults

# Nginx Configuration
rm -rf /etc/nginx/conf.d
mkdir -p /etc/nginx/conf.d
cp conf/nginx.conf /etc/nginx/nginx.conf
cp conf/nginx-status.conf /etc/nginx/conf.d/status.conf
cp conf/foonet.org.conf /etc/nginx/conf.d
mkdir -p /etc/nginx/domains/foonet.org/{public,log,ssl}
echo "There is nothing more to see here, you can leave now." > /etc/nginx/domains/foonet.org/public/index.html
cp conf/foonet.org.pem /etc/nginx/domains/foonet.org/ssl
cp conf/foonet.org.key /etc/nginx/domains/foonet.org/ssl
for i in `cat conf/error_page`
do
	echo "$i" > /etc/nginx/domains/foonet.org/public/$i.html
done
update-rc.d nginx defaults
chown -R root:root /etc/nginx

# Exim configuration
cp conf/exim4.conf.template /etc/exim4
cp conf/dnsbl.conf /etc/exim4
cp conf/spam-blocks.conf /etc/exim4
cp conf/white-blocks.conf /etc/exim4
cp conf/send_limits /etc/exim4
mkdir -p /etc/exim4/domains
chmod +x /etc/exim4/domains
chmod 640 /etc/exim4/exim4.conf.template
gpasswd -a Debian-exim mail
rm -f /etc/alternatives/mta
ln -s /usr/sbin/exim4 /etc/alternatives/mta
mkdir -p /etc/exim4/domains/foonet.org
cp conf/aliases /etc/exim4/domains/foonet.org/aliases
touch /etc/exim4/domains/foonet.org/antispam
touch /etc/exim4/domains/foonet.org/dkim.pem
touch /etc/exim4/domains/foonet.org/fwd_only
touch /etc/exim4/domains/foonet.org/antispam
cp conf/passwd /etc/exim4/domains/foonet.org/passwd
useradd -m god -s /bin/bash
chown -R root:dovecot /etc/exim4
chown -R Debian-exim:dovecot /etc/exim4/domains
update-rc.d exim4 defaults

# Dovecot configuration
rm -rf /etc/dovecot/conf.d /etc/dovecot/*.ext /etc/dovecot/README
mkdir -p /etc/dovecot/conf.d
cp conf/dovecot.conf /etc/dovecot/dovecot.conf
cp conf/10-auth.conf /etc/dovecot/conf.d
cp conf/10-logging.conf /etc/dovecot/conf.d
cp conf/10-mail.conf /etc/dovecot/conf.d
cp conf/10-master.conf /etc/dovecot/conf.d
cp conf/10-ssl.conf /etc/dovecot/conf.d
cp conf/20-imap.conf /etc/dovecot/conf.d
cp conf/20-pop3.conf /etc/dovecot/conf.d
cp conf/auth-passwdfile.conf.ext /etc/dovecot/conf.d
chown -R root:root /etc/dovecot
gpasswd -a dovecot mail
update-rc.d dovecot defaults

# SpamAssassin configuration
sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/spamassassin
sed -i "s/#rewrite_header/rewrite_header/" /etc/spamassassin/local.cf
update-rc.d spamassassin defaults

# Exim add mails
fw=$(PASS)
echo "a:$(doveadm pw -s md5 -p $fw):god:mail::/home/god:0" > /etc/exim4/domains/foonet.org/passwd
mkdir -p p
echo $fw > p/a_foonet.org.p
for i in `cat conf/domains`
do
	./bin/add_mail.sh $i a
done
chown -R root:dovecot /etc/exim4
chown -R Debian-exim:dovecot /etc/exim4/domains

service bind9 start
service exim4 start
service dovecot start
service nginx start
service spamassassin start
