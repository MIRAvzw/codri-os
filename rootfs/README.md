About
=====

This set of scripts allows you to create, configure and finalize a brand new
root filesystem. Note that this excludes a bootloader, kernel, and any modules
(or other hardware-specific files) to get your device to boot.


create
------

This script creates and populates a new root filesystem, using the Debian
multistrap tool. You need to specify the "ARCH" variable in your main profile
settings, and provide a valid multistrap.conf file.


configure
---------

This script configures some common aspects of your system (needing some
settings, see below) and copies user-specified configuration files into the
root filesystem.

Needed variables:
* CONSOLE
* HOSTNAME
* DOMAIN


imagify
-------

This script packages a given rootfs into a dd-able image.


clean
-----

This script cleans a Debian rootfs before packaging.


Prerequisites
=============

Basic set of apps:
* multistrap
* coreutils
* makedev

If running on a foreign architecture:
* binfmt-support
* qemu
*qemu-user-static
