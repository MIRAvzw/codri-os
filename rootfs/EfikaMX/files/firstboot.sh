#!/bin/sh

# Generate a hostname
UID=$(ip addr show dev eth0 | grep ether | awk '{print $2}' | awk 'BEGIN {FS=":"}; {print $4$5$6}')
HOSTNAME=efikamx-$UID
DOMAIN=codri.local
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1       localhost.localdomain localhost" > /etc/hosts
echo "127.0.1.1       $HOSTNAME.$DOMAIN $HOSTNAME" >> /etc/hosts
invoke-rc.d hostname.sh start
invoke-rc.d avahi-daemon restart

# Configure all remaining packages
dpkg --configure -a

# Set the time
ntpdate be.pool.ntp.org
