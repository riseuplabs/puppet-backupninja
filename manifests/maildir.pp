# maildir handler, as part of a backupninja run.
#
# The maildir handler slowly creates a backup of each user's
# maildir to a remote server. It is designed to be run with
# low overhead in terms of CPU and bandwidth, so it runs pretty
# slow. Hardlinking is used to save storage space. The actual
# maildir is stored within each snapshot directory.
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
define backupninja::maildir($order = 40,
                           $ensure = present,
                           $when = 'everyday at 21:00',
                           $srcdir = false,
                           $destdir = false,
                           $desthost = false,
                           $destuser = false,
                           $destid_file = false,
                           $remove = no,
                           $multiconnection = yes
                          ) {
                          include backupninja::client
                          
                          case $srcdir { false: { err("need to define a source directory to backup!") } }
                          case $destdir { false: { err("need to define a destination directory to backup!") } }
                          case $desthost { false: { err("need to define a destination host for backups!") } }
                          case $destuser { false: { err("need to define a destination user for backups!") } }
                          case $destid_file { false: { err("need to define a ssh key id file to use!") } }

	file { "${backupninja::client::configdir}/${order}_${name}.maildir":
		ensure => $ensure,
		content => template('backupninja/maildir.conf.erb'),
		owner => root,
		group => root,
		mode => 0600,
		require => File["${backupninja::client::configdir}"]
	}
}
