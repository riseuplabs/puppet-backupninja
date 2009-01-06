#!/bin/sh

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

# XXX: taken from utils.sh from nagios-plugins-basic
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

backupdir="<%= real_backupdir -%>"

# XXX: this should be a complete backup registry instead
hosts=`ls $backupdir`
stampfile=$backupdir/.stamp

cd $backupdir
for host in $hosts; do
	flag=""
	type="unknown"
	if [ -d $host ]; then
		# guess the backup type and find a proper stamp file to compare
		# XXX: this doesn't check if the backup was actually successful
		# XXX: the backup type should be part of the machine registry
		if [ -d $host/rdiff-backup ]; then
			flag=$host/rdiff-backup/rdiff-backup-data/backup.log
			type="rdiff"
		elif [ -d $host/dump ]; then
			flag="$host/dump/`ls -tr $host/dump | tail -1`"
			type="dump"
		elif [ -d $host/dup ]; then
			flag="$host/dup/`ls -tr $host/dup | tail -1`"
			type="duplicity"
		else
			printf "$host\tbackups\t$STATE_UNKNOWN\tUNKNOWN unknown system\n"
			continue
		fi
		touch -t `date +%Y%m%d0000.00` $stampfile
		date=`ls -l $flag | awk '{print $6 " " $7}'`
		if [ $flag -nt $stampfile ]; then
			printf "$host\tbackups\t$STATE_OK\tOK timestamp $date\n"
		else
			printf "$host\tbackups\t$STATE_CRITICAL\tCRITICAL timestamp $date\n"
		fi
	else
		printf "$host\tbackups\t$STATE_UNKNOWN\tUNKNOWN timestamp no directory\n"
	fi
done
