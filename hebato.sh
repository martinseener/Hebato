#!/usr/bin/env bash

# Hebato - Hetzner Backup Tool
# v.0.1 (c) 2014 Martin Seener (martin@seener.de)

# User-defined options
# Backup-Space Username
HETZNER_USERNAME="u00000"
# Backup-Space Subdirectory (useful for multiple backupped machines)
HETZNER_SUBDIR=/myMachine
# HETZNER_MOUNTPOINT defines where the Backup-Space is being mounted via SSHFS
HETZNER_MOUNTPOINT=/root/hetzner_backup
# ENCFS_MOUNTPOINT defines the path for EncFS to mount the decrypted Backup-Space
ENCFS_MOUNTPOINT=/root/backup
# Select the EncFS Mode: "s" for standard mode and "p" for paranoia mode (more secure)
# Defaults to "p"
ENCFS_MODE="p"
# ENCFS_KEY defines the keyfile for EncFS
# Default: .ssh/id_rsa private keyfile is used since it provides us with a long key!
ENCFS_KEY=/root/.encfs_key

# Dependency-Check will be implemented later - we assume you have sshfs and encfs packages installed!

logger -t "hebato" "Backup Starting at `date`"

# Mount the Backup-Space if not already done
mount | grep $HETZNER_USERNAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  sshfs -o reconnect $HETZNER_USERNAME@$HETZNER_USERNAME.your-backup.de:$HETZNER_SUBDIR $HETZNER_MOUNTPOINT
  if [ $? -ne 0 ]; then
    logger -t "hebato" "Unable to mount the SSHFS path. Aborting."
    exit 1
  fi
else
  logger -t "hebato" "SSHFS path already mounted. Continuing."
fi

# Check if the EncFS Key is there - if not, create one
if [ ! -f $ENCFS_KEY ]; then
  logger -t "hebato" "EncFS Key is missing. Creating one."
  openssl rand -base64 20 > $ENCFS_KEY
fi

# Mount the EncFS path, if its not already there
mount | grep encfs > /dev/null 2>&1
if [ $? -ne 0 ]; then
  encfs --extpass="cat $ENCFS_KEY" $HETZNER_MOUNTPOINT $ENCFS_MOUNTPOINT <<< $ENCFS_MODE
  if [ $? -ne 0 ]; then
    logger -t "hebato" "Unable to mount the EncFS path. Aborting."
    exit 1
  fi
else
  logger -t "hebato" "EncFS path already mounted. Continuing."
fi

# Everything is mounted - let us run the Backup
# Insert your backup scripts after the ## START comment and before the ## END comment

## START
# Backup and cleanup LDAP
/usr/bin/env bash /var/vmail/backup/backup_openldap.sh
if [ $? -ne 0 ]; then
  logger -t "hebato" "An error occured while backing up LDAP. Continuing."
fi
find $ENCFS_MOUNTPOINT/ldap -mtime +90 -exec rm {} \;
if [ $? -ne 0 ]; then
  logger -t "hebato" "An error occured while cleaning up LDAP. Continuing."
fi

# Backup and cleanup MySQL
/usr/bin/env bash /var/vmail/backup/backup_mysql.sh
if [ $? -ne 0 ]; then
  logger -t "hebato" "An error occured while backing up MySQL. Continuing."
fi
find $ENCFS_MOUNTPOINT/mysql -mtime +90 -exec rm {} \;
if [ $? -ne 0 ]; then
  logger -t "hebato" "An error occured while cleaning up MySQL. Continuing."
fi

# Backup iRedmail emails folder with rdiff-backup
rdiff-backup --no-hard-links /var/vmail/vmail1/ $ENCFS_MOUNTPOINT/vmail1
if [ $? -ne 0 ]; then
  logger -t "hebato" "An error occured while backing up Emails. Continuing."
fi
## END

# Unmounting EncFS if not already done
mount | grep encfs > /dev/null 2>&1
if [ $? -eq 0 ]; then
  fusermount -u $ENCFS_MOUNTPOINT
  if [ $? -ne 0 ]; then
    logger -t "hebato" "Unable to unmount the EncFS path. Aborting."
    exit 1
  fi
else
  logger -t "hebato" "EncFS already unmounted. Continuing."
fi

# Unmounting SSHFS if not already done
mount | grep $HETZNER_USERNAME > /dev/null 2>&1
if [ $? -eq 0 ]; then
  fusermount -u $HETZNER_MOUNTPOINT
  if [ $? -ne 0 ]; then
   logger -t "hebato" "Unable to unmount the SSHFS path. Aborting."
    exit 1
  fi
else
  logger -t "hebato" "SSHFS path already unmounted. Continuing."
fi

# We're done
logger -t "hebato" "Backup successful at `date`!"
exit 0