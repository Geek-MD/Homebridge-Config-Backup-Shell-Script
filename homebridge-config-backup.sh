#!/bin/bash
# homebridge-config-backup.sh v1.2.1
# Bash script that allows you to automate local backup of config.json of a Homebridge instance runing inside a Docker container.

# Define some variables.
NAME="homebridge-config-backup.sh"
COMMAND="./$NAME"
DEFAULT_WORKING_DIR=$(pwd)
WORKING_DIR="$DEFAULT_WORKING_DIR"
DEFAULT_BACKUP_LIMIT=15
BACKUP_LIMIT="$DEFAULT_BACKUP_LIMIT"
VERSION="v1.2.1"
DATE=$(date)

# Print help if requested.
if [[ $1 == "--help" || $1 == "-h" ]]
  then
    echo "NAME:"
    echo "    $NAME - Bash script that allows you to automate local backup of config.json of a Homebridge instance runing inside" 
    echo "    a Docker container"
    echo ""
    echo "SYNOPSIS:"
    echo "    $COMMAND [OPTION]... [ARGUMENT]..."
    echo ""
    echo "DESCRIPTION:"
    echo "    -d, --directory"
    echo "        sets working directory for config backups"
    echo "    -l, --limit"
    echo "        sets an specific limit for the amount of backup files that will be kept"
    echo "    -h, --help"
    echo "        display this help and exit"
    echo "    -v, --version"
    echo "        output version information and exit"
    echo ""
    echo "    The argument for -l or --limit option must be an integer. Default limit is 15 files."
    echo "    The argument for -d or --directory option assumes that the working directory you're setting is a subdirectory of"
    echo "    \$HOME, so don't add \$HOME at the start of the argument. See the examples. Default working directory is where"
    echo "    $NAME is located."
    echo ""
    echo "EXAMPLES:"
    echo "    $COMMAND -d docker/homebridge/backup"
    echo "        set \$HOME/docker/homebridge/backup as the working directory"
    echo "    $COMMAND --limit 30"
    echo "        set 30 as the limit of backup files that will be kept"
    echo ""
    echo "AUTHOR:"
    echo "    Written by Edison Montes M."
    echo "    <https://github.com/Geek-MD/homebridge-config-backup>"
    echo ""
    echo "COPYRIGHT:"
    echo "    MIT License <https://github.com/Geek-MD/homebridge-config-backup/blob/main/LICENSE>."
    echo "    This is free software: you are free to change and redistribute it."
    echo "    There is NO WARRANTY, to the extent permitted by law."
    exit 0
fi

if [[ $1 == "--version" || $1 == "-v" ]]
  then
    echo "$NAME $VERSION"
    echo "MIT License <https://github.com/Geek-MD/homebridge-config-backup/blob/main/LICENSE>."
    echo "This is free software: you are free to change and redistribute it."
    echo "There is NO WARRANTY, to the extent permitted by law."
    echo ""
    echo "Written by Edison Montes M."
    echo "<https://github.com/Geek-MD/homebridge-config-backup>"
    exit 0
fi

if [[ $1 == "--directory" || $1 == "-d" ]]
  then
    WORKING_DIR="$HOME/$2"
  else
    WORKING_DIR="$DEFAULT_WORKING_DIR"
fi
LOG_FILE="${WORKING_DIR}/backup.log"

if [[ $1 == "--limit" || $1 == "-l" ]]
  then
    if [[ $2 =~ ^[0-9]+$ ]]
      then
        echo "--limit argument not integer. Check $COMMAND -v for more info."
        exit 0
    fi
    BACKUP_LIMIT="$2"
  else
    BACKUP_LIMIT="$DEFAULT_BACKUP_LIMIT"
fi

# If backup directory does not exist, then create it.
if test -d "$WORKING_DIR"
  then
    :
  else
    mkdir "$WORKING_DIR"
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

FILE1="${WORKING_DIR}/config.json"
FILE2="${WORKING_DIR}/config.bak"

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

BAK="${WORKING_DIR}/config-${m2}.bak"

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

# If md5sum of config.json is different from config.bak, add log data, copy config.json into config.bak, and copy config.bak into conf>
if [ "$m1" == "$m2" ]
  then
    :
  else
    LOG_DATA="${DATE} : ${BAK}"
    echo "$LOG_DATA" >> "${LOG_FILE}"
    cp "$FILE1" "$FILE2"
    cp "$FILE2" "$BAK"
fi

# Remove local version of config.json
rm "$FILE1"

# Check number of backup files
BACKUP_COUNT=$(find "$WORKING_DIR" -name "config-*.bak" | wc -l)

# If number of backup files is greater than 15, remove older backups
if [ "$BACKUP_COUNT" -gt "$BACKUP_LIMIT" ]
  then
    find "$WORKING_DIR" -name "config-*.bak" | tail --lines=+"$(("$BACKUP_LIMIT" + 1))" | xargs -d '\n' rm
  else
    :
fi
