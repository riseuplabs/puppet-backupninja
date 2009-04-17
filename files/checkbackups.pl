#!/usr/bin/perl -w

# This script is designed to check a backup directory populated with
# subdirectories named after hosts, within which there are backups of various
# types.
#
# Example:
# /home/backup:
# foo.example.com
# 
# foo.example.com:
# rdiff-backup .ssh
#
# rdiff-backup:
# root home rdiff-backup-data usr var
#
# There are heuristics to determine the backup type. Currently, the following
# types are supported:
#
# rdiff-backup: assumes there is a rdiff-backup/rdiff-backup-data/backup.log file
# duplicity: assumes there is a dup subdirectory, checks the latest file
# dump files: assumes there is a dump subdirectory, checks the latest file
#
# This script returns output suitable for send_nsca to send the results to
# nagios and should therefore be used like this:
#
# checkbackups.sh | send_nsca -H nagios.example.com

use Getopt::Std;

# XXX: taken from utils.sh from nagios-plugins-basic
my $STATE_OK=0;
my $STATE_WARNING=1;
my $STATE_CRITICAL=2;
my $STATE_UNKNOWN=3;
my $STATE_DEPENDENT=4;

# gross hack: we look into subdirs to find vservers
my @vserver_dirs = qw{/var/lib/vservers /vservers};

our $opt_d = "/backup";
our $opt_c = 48 * 60 * 60;
our $opt_w = 24 * 60 * 60;

if (!getopts('d:c:w:')) {
	print <<EOF
Usage: $0 [ -d <backupdir> ] [ -c <threshold> ] [ -w <threshold> ]
EOF
	;
	exit();
}

my $backupdir= $opt_d;
my $crit = $opt_c;
my $warn = $opt_w;

# XXX: this should be a complete backup registry instead
my @hosts=qx{ls $backupdir};

chdir($backupdir);
my ($state, $message, @vservers, $host);
foreach $host (@hosts) {
	chomp($host);
	my $flag="";
	my $type="unknown";
	@vservers = ();
	$state = $STATE_UNKNOWN;
	$message = "???";
	if (-d $host) {
		# guess the backup type and find a proper stamp file to compare
		# XXX: this doesn't check if the backup was actually successful
		# XXX: the backup type should be part of the machine registry
		if (-d "$host/rdiff-backup") {
			$flag="$host/rdiff-backup/rdiff-backup-data/backup.log";
			$type="rdiff";
			foreach my $vserver_dir (@vserver_dirs) {
				$dir = "$host/rdiff-backup$vserver_dir";
    				if (opendir(DIR, $dir)) {
    					@vservers = grep { /^[^\.]/ && -d "$dir/$_" } readdir(DIR);
    					closedir DIR;
				}
			}
		} elsif (-d "$host/dump") {
			$flag="$host/dump/" . `ls -tr $host/dump | tail -1`;
			chomp($flag);
			$type="dump";
		} elsif (-d "$host/dup") {
			$flag="$host/dup";
			$type="duplicity";
		} else {
			$message = "unknown system";
			next;
		}
		my @stats = stat($flag);
		if (not @stats) {
			$message = "cannot stat flag $flag";
			next;
		}
		my $t = time();
		my $delta = $t - $stats[9];
		if ($delta > $crit) {
			$state = $STATE_CRITICAL;
		} elsif ($delta > $warn) {
			$state = $STATE_WARNING;
		} elsif ($delta >= 0) {
			$state = $STATE_OK;
		}
		$message = "$delta seconds old";
	} else {
		$message = "no directory";
	}
} continue {
	printf "$host\tbackups\t$state\t$message\n";
	my @dom_sufx = split(/\./, $host);
	my $dom_sufx = join('.', @dom_sufx[1,-1]);
	foreach my $vserver (@vservers) {
		printf "$vserver$dom_sufx\tbackups\t$state\t$message, same as parent: $host\n";
	}
}
