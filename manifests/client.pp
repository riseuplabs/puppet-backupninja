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
    '' => 'doit',
    default => $keymanage
  }
  err("$real_keystore $real_keytype $real_keydestination $real_keyowner $real_keygroup $real_keymanage")
  package { 'backupninja':
    ensure => '0.9.5-3';
  }
  file { $configdir:
    ensure => directory
  }
  define key ( $host=$user, $installkeys=false, $keyowner=false, $keygroup=false, $keystore=false, $keytype=false )
  {
    $install_keys = $installkeys ? {
    	false => "${backupninja::client::real_keymanage}",
	default => $installkeys,
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


    case $install_keys {
      'doit': {
        file { "${backupninja::client::real_keydestination}":
          ensure => directory,
          mode => 700, owner => $key_owner, group => $key_group,
        }
        file { "${backupninja::client::real_keydestination}/id_${key_type}":
          source => "${key_store}/${host}_id_${key_type}",
          mode => 0400, owner => $key_owner, group => $key_group,
          require => File["${backupninja::client::real_keydestination}"],
        }
      }
    }
  }
}


