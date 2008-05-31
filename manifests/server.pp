class backupninja::server {
  $real_backupdir = $backupdir ? {
    '' => "/backup",
    default => $backupdir,
  }
  $real_usermanage = $usermanage ? {
    '' => 'doit',
    default => $usermanage
  }
  $real_backupserver_tag = $backupserver_tag ? {
    '' => $fqdn,
    default => $backupserver_tag
  }
  group { "backupninjas":
    ensure => "present",
    gid => 700
  }
  file { "$real_backupdir":
    ensure => "directory",
    mode => 710, owner => root, group => "backupninjas"
  }
  User <<| tag == "backupninja-$real_backupserver_tag" |>>
  File <<| tag == "backupninja-$real_backupserver_tag" |>>

  # this define allows nodes to declare a remote backup sandbox, that have to
  # get created on the server
  define sandbox($user = false, $host = false, $installuser = true, $dir = false, $backupkeys = false, $uid = false, $gid = "backupninjas") {
    $real_user = $name ? {
      false => $name,
      default => $user,
      '' => $name,
    }
    $real_host = $host ? {
      false => $fqdn,
      default => $host,
    }
    $real_backupkeys = $backupkeys ? {
      false => "$fileserver/keys/backupkeys",
      default => $backupkeys,
    }
    $real_dir = $dir ? {
      false => "${backupninja::server::real_backupdir}/$fqdn",
      default => $dir,
    }
    @@file { "$real_dir":
      ensure => directory,
      mode => 750, owner => $user, group => 0,
      tag => "backupninja-$real_host",
    }
    case $installuser {
      true: {
        @@file { "$real_dir/.ssh":
          ensure => directory,
          mode => 700, owner => $user, group => 0,
          require => File["$real_dir"],
          tag => "backupninja-$real_host",
        }
        @@file { "$real_dir/.ssh/authorized_keys":
          ensure => present,
          mode => 644, owner => 0, group => 0,
          source => "$real_backupkeys/${user}_id_rsa.pub",
          require => File["$real_dir/.ssh"],
          tag => "backupninja-$real_host",
        }
        
        case $uid {
          false: {
            @@user { "$user":
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
            @@user { "$user":
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
  }
}
