#!/bin/bash
# homebridge-config-backup.sh v1.1.0
# Bash script that allows you to automate local backup of config.json of a Homebridge instance runing inside a Docker container.

# Define some variables.
HOMEBRIDGE_BACKUP_DIR='$HOME/docker/homebridge/backup'
LOG_FILE="${HOMEBRIDGE_BACKUP_DIR}/backup.log"
DATE=$(date)
BACKUPLIMIT=15

# If backup directory does not exist, then create it.
if test -d "$HOMEBRIDGE_BACKUP_DIR"
  then
    :
  else
    mkdir "$HOMEBRIDGE_BACKUP_DIR"
fi

# If log file dos not exist, then create it.
if test -f "$LOG_FILE"
  then
    :
  else
    touch "${LOG_FILE}"
fi

DOCKER_ID=$(docker container ls --all --quiet --filter "name=homebridge")

# If Homebridge docker container is not running, log that info.
if [ -z "$DOCKER_ID" ]
  then
    LOG_DATA="${DATE} - Homebridge container not runing."
    echo "$LOG_DATA" >> "${LOG_FILE}"
    exit 1
fi

# Copy config.json from docker container to local.
DOCKERFILE="${DOCKER_ID}:/homebridge/config.json"

FILE1="${HOMEBRIDGE_BACKUP_DIR}/config.json"
FILE2="${HOMEBRIDGE_BACKUP_DIR}/config.bak"

docker cp "$DOCKERFILE" "$FILE1"

# Check md5sum of local config.json
m1=$(md5sum "$FILE1" | cut -d " " -f1)

# If config.bak does not exist, create it from config.json
if test -f "$FILE2"
  then
    :
  else
    cp "$FILE1" "$FILE2"
fi

# Check md5sum of config.bak
m2=$(md5sum "$FILE2" | cut -d " " -f1)

BAK="${HOMEBRIDGE_BACKUP_DIR}/config-${m2}.bak"

# If config-md5sum.bak does not exist, create it from config.bak
if test -f "$BAK"
  then
    :
  else
    cp "$FILE2" "$BAK"
fi

# If log file is empty, add first log data, copy config.json into config.bak, and copy config.bak into config-md5sum.bak
if [ -s "$LOG_FILE" ]
  then 
    :
  else
    LOG_DATA="${DATE} : ${BAK}"
    echo "$LOG_DATA" >> "${LOG_FILE}"
    cp "$FILE1" "$FILE2"
    cp "$FILE2" "$BAK"
    fi

# If md5sum of config.json is different from config.bak, add log data, copy config.json into config.bak, and copy config.bak into config-md5sum.bak
if [ "$m1" == "$m2" ]
  then
    :
  else
    if cmp -s "$FILE1" "$FILE2"
      then
        :
      else
      LOG_DATA="${DATE} : ${BAK}"
      echo "$LOG_DATA" >> "${LOG_FILE}"
      cp "$FILE1" "$FILE2"
      cp "$FILE2" "$BAK"
    fi
fi

# Remove local version of config.json
rm "$FILE1"

# Check number of backup files
BACKUPCOUNT=$(find "$HOMEBRIDGE_BACKUP_DIR" -name "config-*.bak" | wc -l)

# If number of backup files is greater than 15, remove older backups
if [ "$BACKUPCOUNT" -gt "$BACKUPLIMIT" ]
  then
    find "$HOMEBRIDGE_BACKUP_DIR" -name "config-*.bak" | tail --lines=+"$(("$BACKUPLIMIT" + 1))" | xargs -d '\n' rm
  else
    :
fi
