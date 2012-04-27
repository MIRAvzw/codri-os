###########
# MODULES #
###########

define apt::key($ensure, $apt_key_url) {
	case $ensure {
		'present' : {
			exec { "apt-key present $name":
				command		=> "/usr/bin/wget -q $apt_key_url/$name -O - | /usr/bin/apt-key add -",
				unless 		=> "/usr/bin/apt-key list | /bin/grep -c $name",
			}
		}
		'absent' : {
			exec { "apt-key absent $name":
				command		=> "/usr/bin/apt-key del $name",
				onlyif 		=> "/usr/bin/apt-key list | /bin/grep -c $name",
			}
		}
		default: {
			fail "Invalid 'ensure' value '$ensure' for apt::key"
		}
	}
}

define munin::plugin (
	$ensure = "present",
	$script_path_in = '',
	$config = '')
{
	$real_script_path = $script_path_in ? { '' => '/usr/share/munin/plugins', default => $script_path_in }

	$plugin_src = $ensure ? { "present" => $name, default => $ensure }
	$plugin = "/etc/munin/plugins/$name"
	$plugin_conf = "/etc/munin/plugin-conf.d/$name.conf"

	case $ensure {
		"absent": {
			file { $plugin: ensure => absent, }
		}
		default: {
			file { $plugin:
				ensure => "${real_script_path}/${plugin_src}"
			}

		}
	}
	case $config {
		'': {
			file { $plugin_conf: ensure => absent }
		}
		default: {
			case $ensure {
				absent: {
					file { $plugin_conf: ensure => absent }
				}
				default: {
					file { $plugin_conf:
						content => "[${name}]\n$config\n",
						mode => 0644, owner => root, group => 0,
					}
				}
			}
		}
	}
}

define line($file, $line, $ensure = 'present') {
	case $ensure {
		present: {
			exec { "/bin/echo '${line}' >> '${file}'":
				unless => "/bin/grep -qFx '${line}' '${file}'"
			}
		}
		absent: {
			exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
			  onlyif => "/bin/grep -qFx '${line}' '${file}'"
			}
		}
		default : {
			err ( "unknown ensure value ${ensure}" )
		}
	}
}



###########
# CLASSES #
###########

#
# Essential
#

class varia {
	# Clean logfiles

	cron { 'logclean' :
		command		=> 'find /var/log -type f -exec sh -c "> {}" \;',
		user		=> 'root',
		hour		=> '0',
		minute		=> '0',
		ensure		=> present,
	}
}

class kernel {
	# Remove static kernel

	file { '/boot' :
		ensure		=> directory,
		recurse		=> true,
		purge		=> true,
		force		=> true,
		before		=> Package['linux-image']
	}

	file { [ "/lib/firmware/2.6.31.14.27-efikamx", "/lib/modules/2.6.31.14.27-efikamx",
			 "/lib/udev/compat_firmware.sh", "/lib/udev/rules.d/50-compat_firmware.rules" ] :
		ensure		=> absent,
		recurse		=> true,
		force		=> true,
		before		=> Package['linux-image']
	}


	# Install new kernel

	package { 'flasher' :
		name		=> [ 'prep-kernel', 'u-boot-tools'],
		ensure		=> installed
	}

	file { '/boot/boot.script' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/boot/boot.script',
		require		=> Package['flasher'],
		before		=> Package['linux-image']
	}

	package { 'linux-image' :
		name		=> 'linux-image-2.6.31.14.27-efikamx',
		ensure		=> installed,
		require		=> Package['flasher']
	}
}

class repository {
	apt::key { 'repository@codri.local.key' :
		ensure		=> present,
		apt_key_url	=> 'http://debian.codri.local',
		before		=> File['/etc/apt/sources.list.d/codri.list']
	}

	file { '/etc/apt/sources.list.d/codri.list' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/apt/sources.list.d/codri.list',
		notify		=> Exec['update']
	}

	exec { 'update' :
		command		=> '/usr/bin/apt-get -q -q update',
		logoutput	=> false,
		refreshonly	=> false
	}
}


#
# Services
#

class rsyslog {
	package { 'rsyslog' :
		ensure		=> installed
	}

	file { '/etc/rsyslog.d/remote.conf' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/rsyslog.d/remote.conf',
		require		=> Package['rsyslog'],
		notify		=> Service['rsyslog']
	}

	service { 'rsyslog' :
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> true,
		require		=> Package['rsyslog']
	}
}

class mta {
	file { '/tmp/mta.preseed' :
		content		=> template("debian/mta.preseed.erb")
	}

	package { 'mta' :
		name			=> [ 'dma', 'bsd-mailx' ],
		ensure			=> installed,
		responsefile	=> '/tmp/mta.preseed',
		require			=> File['/tmp/mta.preseed']
	}

	line { 'root forward' :
		file		=> '/etc/aliases',
		line		=> 'root:	admin@codri.local'
	}
}

class ssh {
	package { 'openssh-server' :
		ensure		=> installed
	}

	file { '/etc/ssh/sshd_config' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/ssh/sshd_config',
		require		=> Package['openssh-server'],
		notify		=> Service['ssh']
	}

	service { 'ssh' :
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> true,
		require		=> Package['openssh-server']
	}

	ssh_authorized_key { 'Tim Besard' :
		ensure		=> 'present',
		type		=> 'ssh-rsa',
		key			=> 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDQsbdvIVaxkWPOnyW01/MGGLRqrZd3uL0bP0Q3vi+p/ikOh9xDP9dupPPFXHpwKaLwFRwtmyJ5mNiRWKFNVW7xUXvCNLZrBLTXuk7lic9zigRmEDzUXhbQmUHo/uxCa+GgGj2Hw5JOiCUwmcAtMMC5PatbJMb1LfBbstlPBlKONclKuAnBllad8hRoHVg5iW6Fyqg4Oxco332rO7aWn1+V3t4DhbE9icd1esPC4s/nkgiLa648eeLJsWBvyBPfwL8MPBItsTnqD8eRPa1USBKwI7rqJ+lgjN+57eAD5/7CXQFp8w6nLRextMjkOaGB+xDiTC/AxR9MXz4VfKjsz47V',
		user		=> 'root',
	}
}

class ntp {
	# TODO: shouldn't Debian handle this package incompatibility?
	package { 'ntpdate' :
		ensure		=> absent,
		before		=> Package['ntp']
	}

	package { 'ntp' :
		ensure		=> installed
	}

	file { '/etc/ntp.conf' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/ntp.conf',
		require		=> Package['ntp'],
		notify		=> Service['ntp']
	}

	service { 'ntp' :
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> true,
		require		=> Package['ntp']
	}
}

class munin {
	package { 'munin-node' :
		name		=> [ 'munin-node', 'libnet-cidr-perl' ],
		ensure		=> installed
	}

	file { '/etc/munin/munin-node.conf' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/munin/munin-node.conf',
		require		=> Package['munin-node'],
		notify		=> Service['munin-node']
	}

	file { '/etc/munin/plugins' :
		ensure		=> directory,
		recurse		=> true,
		purge		=> true,
		force		=> true,
		require		=> Package['munin-node'],
		notify		=> Service['munin-node']
	}

	munin::plugin {
		'memory' :
			notify => Service['munin-node'] ;
		'users' :
			notify => Service['munin-node'] ;
		'df' :
			config => "env.exclude none unknown iso9660 squashfs udf romfs ramfs debugfs devtmpfs rootfs",
			notify => Service['munin-node'] ;
		'load' :
			notify => Service['munin-node'] ;
		'ntp_offset' :
			notify => Service['munin-node'] ;
		'cpu' :
			notify => Service['munin-node'] ;
		'if_err_eth0' :
			ensure => "if_err_",
			notify => Service['munin-node'] ;
		'if_eth0' :
			ensure => "if_",
			notify => Service['munin-node'] ;
	}

	service { 'munin-node' :
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> false,
		require		=> Package['munin-node']
	}
}

class sudo {
        package { 'sudo' :
                ensure          => installed
        }

        file { '/etc/sudoers' :
                owner           => 'root',
                group           => 'root',
                mode            => '0440',
                source          => 'puppet://puppet.codri.local/files/etc/sudoers',
                require         => Package['sudo']
        }
}

class puppet {
	$minute = generate('/usr/bin/env', 'bash', '-c', 'printf $((RANDOM%60+0))')
	cron { 'puppet' :
		command		=> '/usr/sbin/puppetd --onetime --logdest syslog',
		user		=> 'root',
		hour		=> '03',
		minute		=> $minute,
		ensure		=> present,
	}
}


#
# Application
#

class xserver($device) {
	$packages =	[ 'xserver-xorg', 'xserver-xorg-core',
				  'xserver-xorg-input-evdev',
				  'xserver-xorg-video-fbdev', 'xinit',
				  'libgl1-mesa-dri', 'libgl1-mesa-glx']

	case $device {
		'efikamx' : {
			$xserver::packages += 'xserver-xorg-video-imx'

			file { '/etc/X11/xorg.conf.d' :
				owner		=> 'root',
				group		=> 'root',
				mode		=> '0755',
				ensure		=> directory,
				require		=> Package['xserver']
			}

			file { '/etc/X11/xorg.conf.d/drivers.conf' :
				owner		=> 'root',
				group		=> 'root',
				mode		=> '0644',
				source		=> 'puppet://puppet.codri.local/files/etc/X11/xorg.conf.d/drivers.conf',
				require		=> Package['xserver']
			}
		}
		default: {
			fail "Unknown device type"
		}
	}
	
	package { 'xserver' :
		name		=> $packages,
		ensure		=> installed
	}


	# DPMS blanking
	
	file { '/etc/X11/xorg.conf.d/blanking.conf' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/X11/xorg.conf.d/blanking.conf',
		require		=> Package['xserver']
	}
}

class alsa {
	package { 'alsa' :
		name		=> ['alsa-base', 'alsa-utils'],
		ensure		=> installed,
		notify		=> Exec['alsactl init']
	}

	exec { 'alsactl init' :
		command		=> '/usr/sbin/alsactl init',
		refreshonly	=> true,
		returns		=> 99		# FIXME: alsactl init shouldn't only detect something generic
	}

	file { '/var/lib/alsa/asound.state' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		replace		=> false,	# TODO: check this
		source		=> 'puppet://puppet.codri.local/files/var/lib/alsa/asound.state',
		require		=> Exec['alsactl init'],
		notify		=> Exec['alsactl restore']
	}

	exec { 'alsactl restore' :
		command		=> '/usr/sbin/alsactl restore',
		refreshonly	=> true
	}
}

class codri-client {
	# Codri client application

	package { 'fonts' :
		name		=> ['ttf-freefont', 'ttf-dejavu'],
		ensure		=> installed,
		before		=> Package['codri-client']
	}

	package { 'codri-client' :
		ensure		=> latest
	}


	# Local user which will run the application

	user { 'codri' :
		ensure		=> present,
		groups		=> 'audio',
		require		=> Package['codri-client']
	}

	file { '/var/lib/codri/.xsession' :
		owner		=> 'codri',
		group		=> 'codri',
		mode		=> '0755',
		content		=> "#!/bin/sh\ncodri-client",
		require		=> [Package['codri-client'], File['/etc/default/nodm']],
		notify		=> Exec['xsession-reload']
	}

	file { '/var/lib/codri/.ratpoisonrc' :
		owner		=> 'codri',
		group		=> 'codri',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/var/lib/codri/.ratpoisonrc',
		before		=> Package['xsession']
	}


	# X session management

	package { 'xsession' :
		name		=> ['nodm', 'ratpoison', 'unclutter'],
		ensure		=> installed
	}
	
	file { '/etc/X11/Xwrapper.config' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/X11/Xwrapper.config',
		require		=> Package['xsession'],
		notify		=> Exec['xsession-reload']
	}
	
	file { '/etc/default/nodm' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0644',
		source		=> 'puppet://puppet.codri.local/files/etc/default/nodm',
		require		=> Package['xsession'],
		notify		=> Exec['xsession-reload']
	}
	
	service { 'xsession' :
		name		=> 'nodm',
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> false,
		require		=> Package['xsession']
	}
	
	# BUG (9656 & 7365): Puppet doesn't coalesce the notify events (triggering a 'refresh')
	#                    with the ensure condition (triggering a 'start' when nodm is stopped).
	#
	#                    This causes a 'restart' directly after a 'start', which shouldn't be that
	#                    much of an issue weren't it for a race condition in nodm's init scripts.
	#
	#                    To counter this we use a manual 'refresh' Exec target incorporating a small
	#                    but sufficient waiting time. Incorporating a 'status' check in the init script
	#                    might fix this too.
	exec { 'xsession-reload' :
		command		=> '/bin/sh -c "sleep 5 && /usr/sbin/invoke-rc.d nodm restart"',
		refreshonly	=> true,
		require		=> Service['xsession']
	}
}


#
# Final
#

class monit {
	package { 'monit' :
		ensure		=> installed
	}

	file { '/etc/monit/monitrc' :
		owner		=> 'root',
		group		=> 'root',
		mode		=> '0600',
		source		=> 'puppet://puppet.codri.local/files/etc/monit/monitrc',
		require		=> Package['monit'],
		notify		=> Service['monit']
	}

	service { 'monit' :
		ensure		=> running,
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> true,
		require		=> Package['monit']
	}	
}



#########
# NODES #
#########

node /efikamx-......\./ {
	# Stages

	stage { 'essential' : }
	stage { 'services' :	require => Stage['essential'] }
	stage { 'application' :	require => Stage['essential'] }
	stage { 'final' :		require => Stage['services', 'application'] }


	# Essential configuration

	class {
		'varia' :			stage => essential;
		'repository' :		stage => essential;
	#	'kernel' :			stage => essential, require => Class['repository'];
	}


	# Services

	class {
		'rsyslog' :			stage => services;
		'mta' :				stage => services;
		'ssh' :				stage => services;
		'ntp' :				stage => services;
		'munin' :			stage => services;
		'sudo' :			stage => services;
		'puppet' :			stage => services;
	}


	# Application

	class {
		'xserver' :			stage => application, device => 'efikamx';
		'alsa' :			stage => application;
		'codri-client' :	stage => application, require => Class['alsa', 'xserver'];
	}


	# Final stuff

	class {
		'monit' :			stage => final;
	}
}
