class backupninja::server {
  $backupdir = $backupdir_override ? {
    '' => "/backup",
    default => $backupdir_override,
  }
  $backupkeys = $backupkeys_override ? {
    '' => "$fileserver/keys/backupkeys",
    default => $backupkeys_override,
  }
  group { "backupninjas":
    ensure => "present",
    gid => 700
  }
  file { "$backupdir":
    ensure => "directory",
    mode => 710, owner => root, group => "backupninjas"
  }
  User <<| tag == "backupninja-$fqdn" |>>
  File <<| tag == "backupninja-$fqdn" |>>

  # this define allows nodes to declare a remote backup sandbox, that have to
  # get created on the server
  define sandbox($host = false, $dir = false, $uid = false, $gid = "backupninjas") {
    $real_host = $host ? {
      false => $fqdn,
      default => $host,
    }
    $real_dir = $dir ? {
      false => "${backupninja::server::backupdir}/$fqdn",
      default => $dir,
    }
    $real_backupkeys = $backupkeys ? {
      false => "${backupninja::server::backupkeys}",
      default => $backupkeys,
    }
    @@file { "$real_dir":
      ensure => directory,
      mode => 750, owner => $name, group => 0,
      tag => "backupninja-$real_host",
    }
    @@file { "$real_dir/.ssh":
      ensure => directory,
      mode => 700, owner => $name, group => 0,
      require => File["$real_dir"],
      tag => "backupninja-$real_host",
    }
    @@file { "$real_dir/.ssh/authorized_keys":
      ensure => present,
      mode => 644, owner => 0, group => 0,
      source => "$real_backupkeys/${name}_id_rsa.pub",
      require => File["$real_dir/.ssh"],
      tag => "backupninja-$real_host",
    }
    
    case $uid {
      false: {
        @@user { "$name":
          ensure  => "present",
          gid     => "$gid",
          comment => "$name backup sandbox",
          home    => "$real_dir",
          managehome => true,
          shell   => "/bin/sh",
          password => '*',
          require => Group['backupninjas'],
          tag => "backupninja-$real_host"
        }
      }
      default: {
        @@user { "$name":
          ensure  => "present",
          uid     => "$uid",
          gid     => "$gid",
          comment => "$name backup sandbox",
          home    => "$real_dir",
          managehome => true,
          shell   => "/bin/sh",
          password => '*',
          require => Group['backupninjas'],
          tag => "backupninja-$real_host"
        }
      }
    }
  }
}
