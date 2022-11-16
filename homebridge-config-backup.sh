#!/bin/bash

HOMEBRIDGE_BACKUP_DIR='/<abs_path>/docker/homebridge/backup/'
LOG_FILE="${HOMEBRIDGE_BACKUP_DIR}backup.log"
DATE=$(date)

if test -d "$HOMEBRIDGE_BACKUP_DIR"
  then
    :
  else
    mkdir "$HOMEBRIDGE_BACKUP_DIR"
fi

if test -f "$LOG_FILE"
  then
    :
  else
    touch "${LOG_FILE}"
fi

DOCKER_ID=$(docker container ls --all --quiet --filter "name=homebridge")

if [ -z "$DOCKER_ID" ]
  then
    LOG_DATA="${DATE} - Homebridge container not runing."
    echo "$LOG_DATA" >> "${LOG_FILE}"
    exit 1
fi

DOCKERFILE="${DOCKER_ID}:/homebridge/config.json"

FILE1="${HOMEBRIDGE_BACKUP_DIR}config.json"
FILE2="${HOMEBRIDGE_BACKUP_DIR}config.bak"

docker cp "$DOCKERFILE" "$FILE1"

m1=$(md5sum "$FILE1" | cut -d " " -f1)

if test -f "$FILE2"
  then
    :
  else
    cp "$FILE1" "$FILE2"
fi

m2=$(md5sum "$FILE2" | cut -d " " -f1)

BAK="${HOMEBRIDGE_BACKUP_DIR}config-${m2}.bak"

if test -f "$BAK"
  then
    :
  else
    cp "$FILE2" "$BAK"
fi

if [ -s "$LOG_FILE" ]
  then 
    :
  else
    LOG_DATA="${DATE} : ${BAK}"
    echo "$LOG_DATA" >> "${LOG_FILE}"
    cp "$FILE1" "$FILE2"
    cp "$FILE2" "$BAK"
    fi

if [ $m1 == $m2 ]
  then
    :
  else
    LOG_DATA="${DATE} : ${BAK}"
    echo "$LOG_DATA" >> "${LOG_FILE}"
    cp "$FILE1" "$FILE2"
    cp "$FILE2" "$BAK"
fi

rm "$FILE1"
