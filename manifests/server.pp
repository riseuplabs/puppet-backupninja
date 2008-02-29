class backupninja::server {
    $backupdir = $backupdir_override ? {
            '' => "/backup",
	    default => $backupdir_override,
    }
    group { "backupninjas":
            ensure => "present",
            gid => 700
    }
    file { "$backupdir":
            ensure => "directory",
            mode => 750, owner => root, group => "backupninjas"
    }
    User <<| tag == "backupninja-$fqdn" |>>

    # this define allows nodes to declare a remote backup sandbox, that have to
    # get created on the server
    define sandbox($host, $dir = false, $uid = false, $gid = "backupninjas") {
        $real_dir = $dir ? {
	    false => "${backupninja::server::backupdir}/$fqdn",
	    default => $dir,
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
                    require => [ Group['backupninjas'], File["/backup"] ],
                    tag => "backupninja-$host"
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
                    require => [ Group['backupninjas'], File["/backup"] ],
                    tag => "backupninja-$host"
                }
            }
        }
    }
}
