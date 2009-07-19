class backupninja::client {
  $configdir = $cfg_override ? {
    '' => "/etc/backup.d",
    default => $cfg_override,
  }
  $real_keystore = $backupkeystore ? {
    '' => "$fileserver/keys/backupkeys",
    default => $backupkeystore,
  }
  $real_keytype = $backupkeytype ? {
    '' => 'rsa',
    default => $backupkeytype,
  }
  $real_keydestination = $keydestination ? {
    '' => '/root/.ssh',
    default => $keydestination,
  }
  $real_keyowner = $keyowner ? {
    '' => 0,
    default => $keyowner,
  }
  $real_keygroup = $keygroup ? {
    '' => 0,
    default => $keygroup,
  }
  $real_keymanage = $keymanage ? {
    '' => true,
    default => $keymanage
  }
  $real_ssh_dir_manage = $ssh_dir_manage ? {
    '' => true,
    default => $ssh_dir_manage
  }
  package { 'backupninja':
    ensure => '0.9.6-4';
  }
  file { $configdir:
    ensure => directory
  }
  define key(
    $user = false, $host = false, $installkey=false, $keyowner=false,
    $keygroup=false, $keystore=false, $keytype=false)
  {
    $real_user = $user ? {
      false => $name,
      default => $user
    }
    $real_host = $host ? {
      false => $user,
      default => $host
    }
    $install_key = $installkey ? {
    	false => "${backupninja::client::real_keymanage}",
	default => $installkey,
    }
    $key_owner = $keyowner ? {
    	false => "${backupninja::client::real_keyowner}",
	default => $keyowner,
    }
    $key_group = $keygroup ? {
    	false => "${backupninja::client::real_keygroup}",
	default => $keygroup,
    }
    $key_store = $keystore ? {
    	false => "${backupninja::client::real_keystore}",
	default => $keystore,
    }
    $key_type = $keytype ? {
    	false => "${backupninja::client::real_keytype}",
	default => $keytype,
    }

    case $install_key {
      true: {
        file { "${backupninja::client::real_keydestination}":
          ensure => directory,
          mode => 0700, owner => $key_owner, group => $key_group,
        }
        file { "${backupninja::client::real_keydestination}/id_${key_type}":
          source => "${key_store}/${real_user}_id_${key_type}",
          mode => 0400, owner => $key_owner, group => $key_group,
          require => File["${backupninja::client::real_keydestination}"],
        }
      }
    }
  }
}

class backupninja::client::maildir inherits backupninja::client {

  if !defined(Package["rsync"]) {
    if $rsync_ensure_version == '' { $rsync_ensure_version = 'installed' }
    package { 'rsync':
      ensure => $rsync_ensure_version,
    }
  } 
}

class backupninja::client::rdiff_backup inherits backupninja::client {

  if !defined(Package["rdiff-backup"]) {
    if $rdiff_backup_ensure_version == '' { $rdiff_backup_ensure_version = 'installed' }
    package { 'rdiff-backup':
      ensure => $rdiff_backup_ensure_version,
    }
  }
}
