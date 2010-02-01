# sys handler, as part of a backupninja run.
#
# Valid attributes for this type are:
#
#   order: The prefix to give to the handler config filename, to set
#      order in which the actions are executed during the backup run.
#
#   ensure: Allows you to delete an entry if you don't want it any more
#      (but be sure to keep the configdir, name, and order the same, so
#      that we can find the correct file to remove).
#
# 
define backupninja::sys($order = 30,
                           $ensure = present,
                           $parentdir = '/var/backups',
                           $packages = yes,
                           $packagesfile = '/var/backups/dpkg-selections.txt',
                           $partitions = yes,
                           $partitionsfile = '/var/backups/partitions.__star__.txt',
                           $dosfdisk = yes,
                           $hardware = yes,
                           $hardwarefile = '/var/backups/hardware.txt',
                           $dohwinfo = yes,
                           $doluks = no,
                           $dolvm = no
                          ) {
                          include backupninja::client::defaults
	file { "${backupninja::client::defaults::configdir}/${order}_${name}.sys":
		ensure => $ensure,
		content => template('backupninja/sys.conf.erb'),
		owner => root,
		group => root,
		mode => 0600,
		require => File["${backupninja::client::defaults::configdir}"]
	}
}
