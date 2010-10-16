#!/bin/sh

while [ $# -gt 0 ]; do
	case $1 in
		-h|--help)    # Output usage information
		echo -e "\n Backup => FTP"
		echo -e " Usage: ftp-backup <filename|directory> <ftp host> <ftp user> <ftp pass>\n" ;;
		exit 0
	esac
done
echo

FILE=$1
FTP_HOST=$2
FTP_USER=$3
FTP_PASS=$4

if [[ ! -e $FILE ]]; then
	echo "Error: $FILE cannot be found."
	exit 0
fi

tar cvf /tmp/$FILE.tar $FILE  # Usually /tmp is mounted as a ramdisk
gzip /tmp/$FILE.tar           # Compress

ftp -in << "TERM"
	open $FTP_HOST
	user $FTP_USER $FTP_PASS
	binary
	hash
	prompt
	put $FILE.tar.gz
	bye
TERM
exit 0
