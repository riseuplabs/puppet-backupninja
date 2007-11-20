# Run rdiff-backup as part of a backupninja run.
#
# Valid attributes for this type are:
#
#   configdir: The directory to write the handler config file into.
#
#   order: The prefix to give to the handler config filename, to set
#      order in which the actions are executed during the backup run.
#
#   ensure: Allows you to delete an entry if you don't want it any more
#      (but be sure to keep the configdir, name, and order the same, so
#      that we can find the correct file to remove).
#
#   keep, include, exclude, type, host, directory, user, sshoptions: As
#      defined in the backupninja documentation.  The options will be placed
#      in the correct sections automatically.  The include and exclude
#      options should be given as arrays if you want to specify multiple
#      directories.
# 
define backupninja::rdiff($configdir = '/etc/backup.d',
                           $order = 90,
                           $ensure = present,
                           $user = false,
                           $directory = false,
                           $host = false,
                           $type = 'local',
                           $exclude = false,
                           $include = false,
                           $keep = 30,
                           $sshoptions = false,
                           $options = false
                          ) {
	# Make sure the directory that the config goes into exists already
	if defined(File["${configdir}"]) {
		# Yay for a lack of a negation operator, and the inability
		# to provide empty blocks
		include null_class
	} else {
		file { $configdir:
			ensure => directory
		}
	}

	file { "${configdir}/${order}_${name}.rdiff":
		ensure => $ensure,
		content => template('backupninja/rdiff.conf.erb'),
		owner => root,
		group => root,
		mode => 0600,
		require => File["${configdir}"]
	}
}
