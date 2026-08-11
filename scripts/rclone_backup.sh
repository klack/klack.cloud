#!/bin/bash

if [ "$(basename "$PWD")" != "klack.cloud" ]; then
  echo "Must be run from base project directory"
  exit 1
fi

source ./.env

LOG_FILE=/var/log/rclone/rclone.log

OUTPUT=$(/usr/bin/rclone copy -v "${DIR_BACKUPS}/" koofr:backups/ 2>&1)
EXIT_CODE=$?

{
  echo "$OUTPUT"
  if [ $EXIT_CODE -eq 0 ]; then
    echo "RCLONE_BACKUP_RESULT status=SUCCESS exit_code=0"
  else
    REASON=unknown
    if echo "$OUTPUT" | grep -qiE "quota|insufficient|not enough space|no space|507|storage limit"; then
      REASON=destination_full
    fi
    echo "RCLONE_BACKUP_RESULT status=FAILED exit_code=${EXIT_CODE} reason=${REASON}"
  fi
} >> "$LOG_FILE"

exit $EXIT_CODE
