#!/bin/sh
set -x

# FIXME: multistrap doesn't properly call preinstall scripts
/var/lib/dpkg/info/dash.preinst install

# Configure all packages
dpkg --configure -a

# Set the root password
passwd

# Prevent udev from upgrading (since we use a hacked initscript)
echo "udev hold" | dpkg --set-selections

