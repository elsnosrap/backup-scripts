# Overview
These scripts run backups for other computers I maintain. There are two versions of these scripts. They both use rsync for backing up files. They run on a PC running Linux (specifically Xubuntu).

## SSH scripts
Files in the ssh directory use rsync over SSH. This script is useful for OSes that can run SSH (Linux, MacOS, etc).

## Local scripts
Files in the local directory use rsync over a local directory. This script is useful for  Windows-based PCs, where I mount the Windows PC via cifs.

## Back up Clean up
The purge-old-backups.sh script removes old backups so they don't take up too much disk space.

## Crontab
This file contains an example crontab used to schedule backups that run on a nightly basis.