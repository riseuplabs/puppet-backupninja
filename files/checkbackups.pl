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
foreach my $host (@hosts) {
	chomp($host);
	my $flag="";
	my $type="unknown";
	if (-d $host) {
		# guess the backup type and find a proper stamp file to compare
		# XXX: this doesn't check if the backup was actually successful
		# XXX: the backup type should be part of the machine registry
		if (-d "$host/rdiff-backup") {
			$flag="$host/rdiff-backup/rdiff-backup-data/backup.log";
			$type="rdiff";
		} elsif (-d "$host/dump") {
			$flag="$host/dump/" . `ls -tr $host/dump | tail -1`;
			chomp($flag);
			$type="dump";
		} elsif (-d "$host/dup") {
			$flag="$host/dup";
			$type="duplicity";
		} else {
			printf "$host\tbackups\t$STATE_UNKNOWN\tunknown system\n";
			next;
		}
		my @stats = stat($flag);
		if (not @stats) {
			printf "$host\tbackups\t$STATE_UNKNOWN\tcannot stat flag $flag\n";
			next;
		}
		my $t = time();
		my $delta = $t - $stats[9];
		my $state = $STATE_UNKNOWN;
		if ($delta > $crit) {
			$state = $STATE_CRITICAL;
		} elsif ($delta > $warn) {
			$state = $STATE_WARNING;
		} elsif ($delta >= 0) {
			$state = $STATE_OK;
		}
		print "$host\t";
		print "backups\t$state";
		print "\t$delta seconds old\n";
	} else {
		printf "$host\tbackups\t$STATE_UNKNOWN\tno directory\n";
	}
}
