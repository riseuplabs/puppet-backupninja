class backupninja::client {
  $configdir = $cfg_override ? {
    '' => "/etc/backup.d",
    default => $cfg_override,
  }
  $real_keystore = $backupkeystore ? {
    '' => '$fileserver/keys/backupkeys',
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
  package { 'backupninja':
    ensure => '0.9.5-3';
  }
  file { $configdir:
    ensure => directory
  }
  define key (
    $sourcekey='$real_keystore/${name}_id_$real_keytype',
    $destination='$real_keydestination', $key_type=$real_keytype,
    $key_owner=$real_keyowner, $key_group=$real_keygroup, $installkey=$real_keymanage
  )
  case $installkey {
    true: {
      {
        file { "$destination":
          ensure => directory,
          mode => 700, owner => $keyowner, group => $keygroup,
        }
        file { "$destination/id_$keytype":
          source => "$sourcekey",
          mode => 0400, owner => $keyowner, group => $keygroup,
          require => File["$destination"],
        }
      }
    }
  }
}
