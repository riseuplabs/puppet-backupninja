# Run rdiff-backup as part of a backupninja run.
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
#   keep, include, exclude, type, host, directory, user, sshoptions: As
#      defined in the backupninja documentation.  The options will be placed
#      in the correct sections automatically.  The include and exclude
#      options should be given as arrays if you want to specify multiple
#      directories.
# 
define backupninja::rdiff(
  $order = 90, $ensure = present, $user = false, $directory = false, $host = false,
  $type = 'local',
  $exclude = [ "/home/*/.gnupg", "/home/*/.local/share/Trash", "/home/*/.Trash",
               "/home/*/.thumbnails", "/home/*/.beagle", "/home/*/.aMule",
               "/home/*/gtk-gnutella-downloads" ],
  $include = [ "/var/spool/cron/crontabs", "/var/backups", "/etc", "/root",
               "/home", "/usr/local/*bin", "/var/lib/dpkg/status*" ],
  $vsinclude = false, $keep = 30, $sshoptions = false, $options = false, $ssh_dir_manage = true,
  $ssh_dir = false, $authorized_keys_file = false, $installuser = true, $installkey = true,
  $backuptag = false, $home = false, $backupkeytype = '')
{
  include backupninja::client

  case $directory { false: { err("need to define a directory for where the backups should go!") } }
  
  case $type {
    'remote': {
      case $host { false: { err("need to define a host for remote backups!") } }
      
      $real_home = $home ? {
        false => $directory,
        default => $home,
      }

      backupninja::server::sandbox
      {
        "${user}-${name}": user => $user, host => $host, dir => $real_home,
        manage_ssh_dir => $ssh_dir_manage, ssh_dir => $ssh_dir,
        authorized_keys_file => $authorized_keys_file, installuser => $installuser,
        backuptag => $backuptag, keytype => $backupkeytype,
      }
      
      backupninja::client::key
      {
        "${user}-${name}": user => $user, host => $host,
        installkey => $installkey
      }
    }
  }
  file { "${backupninja::client::configdir}/${order}_${name}.rdiff":
    ensure => $ensure,
    content => template('backupninja/rdiff.conf.erb'),
    owner => root,
    group => root,
    mode => 0600,
    require => File["${backupninja::client::configdir}"]
  }
}
  
