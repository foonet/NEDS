#!/bin/bash
#
# 1.domain
# 2.name
#

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

mkdir -p /etc/exim4/domains/$1
touch /etc/exim4/domains/$1/aliases
touch /etc/exim4/domains/$1/antispam
touch /etc/exim4/domains/$1/dkim.pem
touch /etc/exim4/domains/$1/fwd_only
touch /etc/exim4/domains/$1/antispam
touch /etc/exim4/domains/$1/passwd
fw=$(PASS)
echo "$2:$(doveadm pw -s md5 -p $fw):god:mail::/home/god:0" > /etc/exim4/domains/$1/passwd
echo $fw > ./p/$2_$1.p
echo "$2@$1: 100" >> /etc/exim4/send_limits
chown -R root:dovecot /etc/exim4
chown -R Debian-exim:dovecot /etc/exim4/domains
