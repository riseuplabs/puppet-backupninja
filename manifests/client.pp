class backupninja::client {
  $configdir = $cfg_override ? {
    '' => "/etc/backup.d",
    default => $cfg_override,
  }
  package { 'backupninja':
    ensure => '0.9.5-3';
  }
  file { $configdir:
    ensure => directory
  }
}
