#!/usr/bin/env bash

# Hebato - Hetzner Backup Tool
# v1.0 (c) 2014-2016 Martin Seener (martin@seener.de)

set -e

# User-defined options
# Hetzner Backup-Space or Storage-Box?
HETZNER_SPACETYPE="Backup" # or "Storage"
# Backup-Space/Storage-Box Username
HETZNER_USERNAME="u00000"
# Backup-Space/Storage-Box Subdirectory (useful for multiple backupped machines)
HETZNER_SUBDIR=/myMachine
# HETZNER_MOUNTPOINT defines where the Backup-Space/Storage-Box is being mounted via SSHFS
HETZNER_MOUNTPOINT=/root/hetzner_backup
# ENCFS_MOUNTPOINT defines the path for EncFS to mount the decrypted Backup-Space/Storage-Box
ENCFS_MOUNTPOINT=/root/backup
# Select the EncFS Mode: "s" for standard mode and "p" for paranoia mode (more secure)
# Defaults to "p"
ENCFS_MODE="p"
# ENCFS_KEY defines the keyfile for EncFS
# Default: /root/.encfs_key private keyfile is used since it provides us with a long key!
ENCFS_KEY=/root/.encfs_key
# ENCFS_KEY keylength
ENCFS_KEYLENGTH=50
# Logging to Syslog
# Default: INFO. Can be NONE, INFO, DEBUG
LOG_LEVEL="INFO"
# Optional log to STDOUT (interactive mode)
LOG_STDOUT=false

## CORE METHODS
# Logging method
log() {
    if [ "${LOG_LEVEL}" != "NONE" ]; then
        # Log only if DEBUG-Mode is active and -d option is given
        if [ "${LOG_LEVEL}" == "DEBUG" ] && [ "$1" == "-d" ]; then
            logger -t "hebato/${HETZNER_USERNAME}[$$]" "$2"
            if ${LOG_STDOUT}; then
                echo "hebato/${HETZNER_USERNAME}[$$]: $2"
            fi
        fi
        # Log INFO only if -d is NOT given
        if [[ "${LOG_LEVEL}" =~ ^(INFO|DEBUG)$ ]] && [ "$1" != "-d" ]; then
            logger -t "hebato/${HETZNER_USERNAME}[$$]" "$1"
            if ${LOG_STDOUT}; then
                echo "hebato/${HETZNER_USERNAME}[$$]: $1"
            fi
        fi
    fi
}

# Dependencies check
check_dependencies() {
    PARAM_ARRAY="$1[@]"
    WORK_ARRAY=("${!PARAM_ARRAY}")

    for CMD in "${WORK_ARRAY[@]}"; do
        if ! type -p "${CMD}" >/dev/null 2>&1; then
            log "> ${CMD} < cannot be found on this machine! Aborting."
            exit 1
        fi
    done
}

# Checking mount paths
check_folder() {
    if [ ! -d "$1" ]; then
        if ! mkdir -p "$1"; then
            exit 2
        fi
    fi
}

# Hebato Start
logger -t "hebato/${HETZNER_USERNAME}[$$]" "Starting Hebato."

# Checking dependencies
export DEP
DEP[0]="sshfs"
DEP[1]="encfs"
DEP[2]="rdiff-backup"
check_dependencies "DEP"

# Checking mount paths
check_folder "${HETZNER_MOUNTPOINT}"
check_folder "${ENCFS_MOUNTPOINT}"

# Mount the Backup-Space if not already done
if ! mount | grep ${HETZNER_USERNAME} > /dev/null 2>&1; then
    if [ "${HETZNER_SPACETYPE}" == "Backup" ]; then
        HETZNER_DOMAIN=".your-backup.de"
    else
        HETZNER_DOMAIN=".your-storagebox.de"
    fi
    if ! sshfs -o reconnect ${HETZNER_USERNAME}@${HETZNER_USERNAME}${HETZNER_DOMAIN}:${HETZNER_SUBDIR} ${HETZNER_MOUNTPOINT}; then
        log "Unable to mount the SSHFS path. Aborting."
        exit 1
    fi
else
    log -d "SSHFS path already mounted. Continuing."
fi

# Check if the EncFS Key is there - if not, create one
if [ ! -f ${ENCFS_KEY} ]; then
    log "EncFS Key is missing. Creating one."
    if ! </dev/urandom tr -dc '0-9a-zA-Z!§$%&/()=_#+*' | head -c${ENCFS_KEYLENGTH} > ${ENCFS_KEY}; then
        log "Generating EncFS Key failed. Aborting."
        exit 1
    else
        log -d "EncFS Key successfully generated. Continuing."
    fi
fi

# Mount the EncFS path, if its not already there
if ! mount | grep encfs > /dev/null 2>&1; then
    if ! encfs --extpass="cat ${ENCFS_KEY}" ${HETZNER_MOUNTPOINT} ${ENCFS_MOUNTPOINT} <<< ${ENCFS_MODE}; then
        log "Unable to mount the EncFS path. Aborting."
        exit 1
    fi
    else
        log -d "EncFS path already mounted. Continuing."
fi

# Everything is mounted - let us run the Backup
# Insert your backup scripts after the ## START comment and before the ## END comment

## START
# Backup and cleanup LDAP
if ! /usr/bin/env bash /var/vmail/backup/backup_openldap.sh; then
    log "An error occured while backing up LDAP. Continuing."
else
    log -d "LDAP Backup successful. Continuing."
fi
if ! find ${ENCFS_MOUNTPOINT}/ldap -mtime +90 -exec rm {} \;; then
    log "An error occured while cleaning up LDAP. Continuing."
else
    log -d "LDAP Cleanup successful. Continuing."
fi

# Backup and cleanup MySQL
if ! /usr/bin/env bash /var/vmail/backup/backup_mysql.sh; then
    log "An error occured while backing up MySQL. Continuing."
else
    log -d "MySQL Backup successful. Continuing."
fi
if ! find ${ENCFS_MOUNTPOINT}/mysql -mtime +90 -exec rm {} \;; then
    log "An error occured while cleaning up MySQL. Continuing."
else
    log -d "MySQL Cleanup successful. Continuing."
fi

# Backup iRedmail emails folder with rdiff-backup
if ! rdiff-backup --no-hard-links /var/vmail/vmail1/ ${ENCFS_MOUNTPOINT}/vmail1; then
    log "An error occured while backing up E-Mails. Continuing."
else
    log -d "E-Mail Backup successful. Continuing."
fi
## END

# Unmounting EncFS if not already done
if ! mount | grep encfs > /dev/null 2>&1; then
    if ! fusermount -u ${ENCFS_MOUNTPOINT}; then
        log "Unable to unmount the EncFS path. Aborting."
        exit 1
    fi
else
    log -d "EncFS already unmounted. Continuing."
fi

# Unmounting SSHFS if not already done
if ! mount | grep ${HETZNER_USERNAME} > /dev/null 2>&1; then
    if ! fusermount -u ${HETZNER_MOUNTPOINT}; then
        log "Unable to unmount the SSHFS path. Aborting."
        exit 1
    fi
else
    log -d "SSHFS path already unmounted. Continuing."
fi

# We're done
log "Backup successful. Shutting down Hebato."
exit 0
