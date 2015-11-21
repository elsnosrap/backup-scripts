#!/bin/bash

#=======================================
#
# v1.0 4/22/2011
#   Initial script
#
# v1.1 11/29/2011
#   Changes to accomodate new server and new laptop name
#   Also make sure backup_base_dir exists before starting a backup.
#
# v1.2 12/10/2011
#   Clean up formatting of script
#
# v1.3 12/11/2011
#   Add better error handling
#
# v1.4 9/16/2012
#   Add symbolic link to latest directory
#
# v1.5 11/07/2012
#	Switch to using MSMTP for sending mail
#
# v1.6 12/08/2013
#	Reconfigure to back up Macbook
#=======================================

#=======================================
# VARIABLES
#=======================================
MACHINE_NAME="hostname"
MACHINE_HOST="192.168.2.2"
MACHINE_USER="user-name"
SOURCE_EXCLUDE_FILE="/opt/backups/scripts/exclude-files-laptop"

# Leave this empty, will back up entire home directory
SOURCE_DIR=""

RSYNC_OPTIONS="--archive --hard-links --human-readable --inplace --numeric-ids --delete --delete-excluded --verbose --itemize-changes -e ssh"
TIMEDATE=`eval date +%Y%m%d-%H%M`

# The base directory where all backups are stored
BACKUP_BASE_DIR="/media/backups"

# The log file we will write to during this backup
LOG_FILE="/opt/backups/logs/backup_"$MACHINE_NAME"_"$TIMEDATE".log"
ERR_LOG_FILE="/opt/backups/logs/err_backup_"$MACHINE_NAME"_"$TIMEDATE".log"

# The directory for this machine where all backups will be stored
BACKUP_DIR=$BACKUP_BASE_DIR"/"$MACHINE_NAME

# The name used for this backup
BACKUP_NAME=$MACHINE_NAME"_"$TIMEDATE

# The location for this backup while rsync is running.
BACKUP_STAGING_DIR=$BACKUP_DIR"/incomplete"

# The final directory for this backup
BACKUP_FINAL_DIR=$BACKUP_DIR"/"$BACKUP_NAME

# Email Variables
EMAIL_TO="to@email.com"
EMAIL_FROM="from@email.com"
EMAIL_SUCCESS_SUBJECT="Backup completed successfully for $MACHINE_NAME"
EMAIL_SUCCESS_MESSAGE="The backup for machine $MACHINE_NAME has finished successfully."
EMAIL_FAIL_SUBJECT="Backup FAILED for $MACHINE_NAME"
EMAIL_FAIL_MESSAGE="The backup for $MACHINE_NAME finished with errors.  See attached log file."
EMAIL_FILE=$BACKUP_DIR"/_"$TIMEDATE"_update.email"

#=======================================
# FUNCTIONS
#=======================================
function writeHeader {
    echo "========================================="                            | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " STARTING BACKUP"                                                     | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " Starting at `eval date +%c`"                                         | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Machine name:           $MACHINE_NAME"                            | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Machine user name:      $MACHINE_USER"                            | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Machine source dir:     $SOURCE_DIR"                              | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Backup base directory:  $BACKUP_BASE_DIR"                         | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Time/Date:              $TIMEDATE"                                | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Backup Directory:       $BACKUP_DIR"                              | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Backup Name:            $BACKUP_NAME"                             | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Backup Staging dir:     $BACKUP_STAGING_DIR"                      | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "    Backup Final dir:       $BACKUP_FINAL_DIR"                        | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "========================================="                            | tee -a $LOG_FILE $ERR_LOG_FILE
}

function getLastDirectory {

    # First, check if LATEST_BACKUP even exists
    if [ -f $BACKUP_DIR"/LATEST_BACKUP" ]; then
        # File exists, get last known good directory
        LAST_GOOD_BUILD_NAME=`cat $BACKUP_DIR"/LATEST_BACKUP"`
        LAST_GOOD_DIR=$BACKUP_DIR"/"$LAST_GOOD_BUILD_NAME
    else
        LAST_GOOD_BUILD_NAME=""
        LAST_GOOD_DIR=""
    fi
}

function writeFooter {
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo "========================================="                            | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " FINISHED WITH BACKUP"                                                | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " Finished at `eval date +%c`"                                         | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " "                                                                    | tee -a $LOG_FILE $ERR_LOG_FILE
    echo " Rsync finished with code $1"                                         | tee -a $LOG_FILE $ERR_LOG_FILE
    
    if [ "$1" = "0" ]; then
        echo "     Finished successfully"                                       | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "1" ]; then
        echo "     Syntax or usage error"                                       | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "2" ]; then
        echo "     Protocol incompatibility"                                    | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "3" ]; then
        echo "     Errors selecting input/output files, dirs"                   | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "4" ]; then
        echo "     Requested action not supported: an attempt was made to manipulate 64-bit files on a platform that cannot support them; or an option was specified that is supported by the client and not by the server." | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "5" ]; then
        echo "     Error starting client-server protocol"                       | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "6" ]; then
        echo "     Daemon unable to append to log-file"                         | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "10" ]; then
        echo "     Error in socket I/O"                                         | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "11" ]; then
        echo "     Error in file I/O"                                           | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "12" ]; then
        echo "     Error in rsync protocol data stream"                         | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "13" ]; then
        echo "     Errors with program diagnostics"                             | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "14" ]; then
        echo "     Error in IPC code"                                           | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "20" ]; then
        echo "     Received SIGUSR1 or SIGINT"                                  | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "21" ]; then
        echo "     Some error returned by waitpid()"                            | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "22" ]; then
        echo "     Error allocating core memory buffers"                        | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "23" ]; then
        echo "     Partial transfer due to error"                               | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "24" ]; then
        echo "     Partial transfer due to vanished source files"               | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "25" ]; then
        echo "     The --max-delete limit stopped deletions"                    | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "30" ]; then
        echo "     Timeout in data send/receive"                                | tee -a $LOG_FILE $ERR_LOG_FILE
        
    elif [ "$1" = "35" ]; then
        echo "     Timeout waiting for daemon connection"                       | tee -a $LOG_FILE $ERR_LOG_FILE
    fi
    
    echo "========================================="                            | tee -a $LOG_FILE $ERR_LOG_FILE
}

#=======================================
#
#        START OF BACKUP ROUTINE
#
#=======================================

# Write to log file
writeHeader

# Verify backup destination exists
if [ ! -d "$BACKUP_BASE_DIR" ];then
    echo "Backup base directory does not exist, not performing backup."         | tee -a $LOG_FILE $ERR_LOG_FILE
    exit
fi

# Get last known good backup directory
getLastDirectory
echo " "                                                                        | tee -a $LOG_FILE $ERR_LOG_FILE
echo "Last known good backup directory in $BACKUP_DIR is $LAST_GOOD_DIR"        | tee -a $LOG_FILE $ERR_LOG_FILE

# Based on the value for the last know good directory, set the link-dest option for rsync
if [ "$LAST_GOOD_DIR" = "" ]; then
	# No known good directory
	LINKDEST=""
else
	LINKDEST="--link-dest="$LAST_GOOD_DIR
fi
echo "Option for --link-dest is $LINKDEST"                                      | tee -a $LOG_FILE $ERR_LOG_FILE

# Make destination directory
mkdir -p $BACKUP_STAGING_DIR                                                    >>$LOG_FILE     2>>$LOG_FILE

# Run rsync command
echo "rsync $RSYNC_OPTIONS --exclude-from=$SOURCE_EXCLUDE_FILE $LINKDEST $MACHINE_USER@$MACHINE_HOST:$SOURCE_DIR $BACKUP_STAGING_DIR" | tee -a $LOG_FILE $ERR_LOG_FILE
rsync $RSYNC_OPTIONS --exclude-from=$SOURCE_EXCLUDE_FILE $LINKDEST $MACHINE_USER@$MACHINE_HOST:$SOURCE_DIR $BACKUP_STAGING_DIR          >>$LOG_FILE     2>>$ERR_LOG_FILE
RSYNC_RETURN_CODE=$?

# Check if rsync ran successfully
if [ "$RSYNC_RETURN_CODE" = "0" ]; then

    # Move from staging directory to final directory
    mv $BACKUP_STAGING_DIR $BACKUP_FINAL_DIR                                    >>$LOG_FILE     2>>$LOG_FILE

    # Write this build name to the LATEST_BACKUP file
    echo "$BACKUP_NAME" >$BACKUP_DIR"/LATEST_BACKUP"

    # Create symbolic link to latest directory
    rm $BACKUP_DIR"/latest"
    ln -s $BACKUP_FINAL_DIR $BACKUP_DIR"/latest"
    
fi

# Write footer
writeFooter $RSYNC_RETURN_CODE

# CONSTRUCT EMAIL TO SEND
echo "To: $EMAIL_TO"															>$EMAIL_FILE
echo "From: $EMAIL_FROM"														>>$EMAIL_FILE
if [ "$RSYNC_RETURN_CODE" = "0" ]; then
	echo "Subject: $EMAIL_SUCCESS_SUBJECT"										>>$EMAIL_FILE
	echo " "																	>>$EMAIL_FILE
	echo "$EMAIL_SUCCESS_MESSAGE"												>>$EMAIL_FILE
else
	echo "Subject: $EMAIL_FAIL_SUBJECT"											>>$EMAIL_FILE
	echo " "																	>>$EMAIL_FILE
	echo "$EMAIL_FAIL_MESSAGE"													>>$EMAIL_FILE
	echo " "																	>>$EMAIL_FILE
	cat $ERR_LOG_FILE															>>$EMAIL_FILE	
fi

# SEND EMAIL
cat $EMAIL_FILE | msmtp -a default $EMAIL_TO
