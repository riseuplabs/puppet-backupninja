# Write a "main" configuration file for backupninja.  Effectively, it does
# little more than just take the config options you specify in the define and
# write them to the config file as-is.
#
define backupninja::config(
  $configfile = '/etc/backupninja.conf', $loglvl = 4, $when = 'everyday at 01:00',
  $reportemail = 'root', $reportsuccess = false, $reportwarning = true,
  $reporthost = $reporthost, $reportuser = $reportuser,
  $reportdirectory = $reportdirectory,
  $logfile = '/var/log/backupninja.log', $configdir = '/etc/backup.d',
  $scriptdir = '/usr/share/backupninja', $libdir = '/usr/lib/backupninja',
  $usecolors = true, $vservers = false)
{
  file { $configfile:
    content => template('backupninja/backupninja.conf.erb'),
    owner => root,
    group => root,
    mode => 0644
  }
}
