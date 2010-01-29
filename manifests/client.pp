class backupninja::client::defaults {
  $configdir = $cfg_override ? {
    '' => "/etc/backup.d",
    default => $cfg_override,
  }
  $real_keystore = $backupkeystore ? {
    '' => "$fileserver/keys/backupkeys",
    default => $backupkeystore,
  }
  $real_keytype = $backupkeytype ? {
    ''      => 'rsa',
    false   => 'rsa',
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
  if !defined(Package["backupninja"]) {
    if $backupninja_ensure_version == '' { $backupninja_ensure_version = 'installed' }
    package { 'backupninja':
      ensure => $backupninja_ensure_version
    }
  }
  file { $configdir:
    ensure => directory,
    mode => 750, owner => 0, group => 0;
  }
}

class backupninja::client inherits backupninja::client::defaults {
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
    	false => "${backupninja::client::defaults::real_keymanage}",
	default => $installkey,
    }
    $key_owner = $keyowner ? {
    	false => "${backupninja::client::defaults::real_keyowner}",
	default => $keyowner,
    }
    $key_group = $keygroup ? {
    	false => "${backupninja::client::defaults::real_keygroup}",
	default => $keygroup,
    }
    $key_store = $keystore ? {
    	false => "${backupninja::client::defaults::real_keystore}",
	default => $keystore,
    }
    $key_type = $keytype ? {
    	''    => "${backupninja::client::defaults::real_keytype}",
    	false => "${backupninja::client::defaults::real_keytype}",
	default => $keytype,
    }

    $key_dest      = "${backupninja::client::defaults::real_keydestination}"
    $key_dest_file = "$key_dest/id_$key_type"

    case $install_key {
      true: {
        if !defined(File["$key_dest"]) {
          file { "$key_dest":
            ensure => directory,
            mode => 0700, owner => $key_owner, group => $key_group,
          }
        }
        if !defined(File["$key_dest_file"]) {
          file { "$key_dest_file":
            source => "${key_store}/${real_user}_id_${key_type}",
            mode => 0400, owner => $key_owner, group => $key_group,
            require => File["$key_dest"],
          }
        }
      }
    }
  }
}

class backupninja::client::maildir inherits backupninja::client::defaults {

  if !defined(Package["rsync"]) {
    if $rsync_ensure_version == '' { $rsync_ensure_version = 'installed' }
    package { 'rsync':
      ensure => $rsync_ensure_version,
    }
  } 
}

class backupninja::client::rdiff_backup inherits backupninja::client::defaults {

  if !defined(Package["rdiff-backup"]) {
    if $rdiff_backup_ensure_version == '' { $rdiff_backup_ensure_version = 'installed' }
    package { 'rdiff-backup':
      ensure => $rdiff_backup_ensure_version,
    }
  }
}

class backupninja::client::duplicity inherits backupninja::client::defaults {

  if !defined(Package["duplicity"]) {
    if $duplicity_ensure_version == '' { $duplicity_ensure_version = 'installed' }
    package { 'duplicity':
      ensure => $duplicity_ensure_version,
    }
  }
}

class backupninja::client::sys inherits backupninja::client::defaults {
  case $operatingsystem {
    debian,ubuntu: {
      if !defined(Package["debconf-utils"]) {
	if $debconf_utils_ensure_version == '' { $debconf_utils_ensure_version = 'installed' }
	package { 'debconf-utils':
	  ensure => $debconf_utils_ensure_version,
	}
      }
      if !defined(Package["hwinfo"]) {
	if $hwinfo_ensure_version == '' { $hwinfo_ensure_version = 'installed' }
	package { 'hwinfo':
	  ensure => $hwinfo_ensure_version,
	}
      }
    }
    default: {}
  }
}  
