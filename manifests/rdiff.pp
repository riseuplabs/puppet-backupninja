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
  $order = 90, $ensure = present, $user = false, $home = false, $host = false,
  $type = 'local',
  $exclude = [ "/home/*/.gnupg", "/home/*/.local/share/Trash", "/home/*/.Trash",
               "/home/*/.thumbnails", "/home/*/.beagle", "/home/*/.aMule",
               "/home/*/gtk-gnutella-downloads" ],
  $include = [ "/var/spool/cron/crontabs", "/var/backups", "/etc", "/root",
               "/home", "/usr/local/*bin", "/var/lib/dpkg/status*" ],
  $vsinclude = false, $keep = 30, $sshoptions = false, $options = '--force', $ssh_dir_manage = true,
  $ssh_dir = false, $authorized_keys_file = false, $installuser = true, $installkey = true, $key = false,
  $backuptag = false, $home = false, $backupkeytype = "rsa", $backupkeystore = false, $extras = false)
{
  include backupninja::client::rdiff_backup

  case $type {
    'remote': {
      case $host { false: { err("need to define a host for remote backups!") } }
      $real_backuptag = $backuptag ? {
          false => "backupninja-$host",
          default => $backuptag
      }

      $real_home = $home ? {
        false => "/home/${user}-${name}",
        default => $home,
      }
      $directory = "$real_home/rdiff-backup/"

      backupninja::server::sandbox
      {
        "${user}-${name}": user => $user, host => $fqdn, dir => $real_home,
        manage_ssh_dir => $ssh_dir_manage, ssh_dir => $ssh_dir, key => $key,
        authorized_keys_file => $authorized_keys_file, installuser => $installuser,
        backuptag => $real_backuptag, keytype => $backupkeytype, backupkeys => $backupkeystore,
      }
     
      backupninja::client::key
      {
        "${user}-${name}": user => $user, host => $host,
        installkey => $installkey,
        keytype => $backupkeytype,
        keystore => $backupkeystore,
      }
    }
  }
  file { "${backupninja::client::defaults::configdir}/${order}_${name}.rdiff":
    ensure => $ensure,
    content => template('backupninja/rdiff.conf.erb'),
    owner => root,
    group => root,
    mode => 0600,
    require => File["${backupninja::client::defaults::configdir}"]
  }
}
  
