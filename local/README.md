# Overview
| File | Description |
| ---- | --------------- |
| backup-local.sh | This is the script that actually performs the backup operation. |
| exclude-files-local | This file contains a list of all directories that should _NOT_ be backed up. |
| .smbcredentials | An example file that should contain credentials used to mount a Windows-based PC. |
| README.md | This file.|

## Set up
Before running this script, a Windows-based PC must be mounted on the local machine. The easiest way to do this is using cifs. Make sure the ```cifs-utils``` package is installed on the host machine.

1. Modify the ```.smbcredentials``` file so it includes the actual user's name and password.
2. Copy the ```.smbcredentials``` file to ```/opt/smbcreds``` and make it read-only for root (to prevent unauthorized access).
3. Modify ```/etc/fstab``` to mount the PC:
```
//<Computer Name>/<User name> /mnt/windows-pc cifs credentials=/opt/smbcreds/.smbcredentials,iocharset=utf8,file_mode=0777,dir_mode=077 0 0
``` 
Be sure to enter your actual computer's name and user's name.

You will now be able to mount the user's directory in read-write mode. If you wish to mount it in read-only mode, replace ```file_mode=0777,dir_mode=077``` with ```ro```.
