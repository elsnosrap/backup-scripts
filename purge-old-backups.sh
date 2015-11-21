#!/bin/bash

#======================================
# Purges old log files and backups
#
# v1.0 Dec 10 2011
#   Initial Script
#======================================

#======================================
# VARIABLES
#======================================

# Anything older that PURGE_DAYS will be purged
PURGE_DAYS=10

# Directories to run our delete command on
# Enter any new directories on a separate line, within the quotation marks
PURGE_DIRECTORIES="/opt/backups/logs
/media/backups/windows-pc"

# Time Date stamp
TIMEDATE=`eval date +%Y%m%d-%H%M`

# The log file we will write to during this backup
LOG_FILE="/opt/backups/logs/purge-old-backups_"$TIMEDATE".log"

#=======================================
# FUNCTIONS
#=======================================
function writeHeader {
    echo "========================================="                            >$LOG_FILE
    echo " STARTING PURGE"                                                      >>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
    echo " Starting at `eval date +%c`"                                         >>$LOG_FILE
    echo " All files and directories older than $PURGE_DAYS days will be deleted">>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
    echo " Following directories will be purged:"                               >>$LOG_FILE
    
    for purgePath in $PURGE_DIRECTORIES
    do
        echo "    $purgePath"                                                   >>$LOG_FILE
    done
    
    echo " "                                                                    >>$LOG_FILE
    echo "========================================="                            >>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
}

function writeFooter {
    echo " "                                                                    >>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
    echo "========================================="                            >>$LOG_FILE
    echo " FINISHED WITH PURGE"                                                 >>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
    echo " Finished at `eval date +%c`"                                         >>$LOG_FILE
    echo " "                                                                    >>$LOG_FILE
    echo "========================================="                            >>$LOG_FILE
}

#=======================================
# START OF PURGE ROUTINE
#=======================================

# Write header to log file
writeHeader

echo " Deleting following files and directories"                                >>$LOG_FILE

# Remove all files / directories in list, that match criteria
for purgePath in $PURGE_DIRECTORIES
do
    find $purgePath -maxdepth 1 -mtime +$PURGE_DAYS | sort                       >>$LOG_FILE 2>>$LOG_FILE
    find $purgePath -maxdepth 1 -mtime +$PURGE_DAYS -delete                      >>$LOG_FILE 2>>$LOG_FILE
done

# Write footer
writeFooter
