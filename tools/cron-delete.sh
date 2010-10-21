#!/bin/env bash

DEL_PATH=/path/to/files  # Path to folder where you want to delete from
DAYS=5                   # Files older than this will be deleted
LOG=/path/to/log         # Path to logfile

if [[ -d $DEL_PATH && $DAYS > 0 ]]; then
	date >> $LOG
	find $DEL_PATH* -mtime +$DAYS -exec rm -v {} \; >> $LOG
else
	echo " Invalid Path -or- Days "
fi
exit
