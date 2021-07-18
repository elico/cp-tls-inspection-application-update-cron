#!/usr/bin/env bash

if [ "$( pt users -f username $USER -F role | head -n 1 | grep -v {} )" != "ROLE.SUPER" ];then
          echo "This script can only run from a user with ROLE.SUPER ie super user"
          exit 1
fi

echo "Started Running: \"$0\"" |logger
START_EXECUTION_TIME=$( date +"%Y_%m_%d_%H_%M_%SS" )
START_EXECUTION_DATE=$( date +"%Y_%m_%d" )

DEBUG="0"
DRY_RUN="0"
CLEANUP_AFTER="1"
LOCK_FILE="/tmp/clish-scripts-collector-cron-lockfile"
SCRIPTS_PATH="/storage/clish-scripts"
ARCHIVE_PATH="/storage/clish-scripts-execution-archive"

if [ -f "${LOCK_FILE}" ];then
        echo "Lockfile exits, stopping update"
        exit 0
fi

echo "Creating LOCKFILE: \"${LOCK_FILE}\""
touch "${LOCK_FILE}"

if [ -f "debug" ];then
        DEBUG="1"
fi

if [ -f "dry-run" ];then
        DRY_RUN="1"
fi

if [ -f "cleanup-after" ];then
        CLEANUP_AFTER="1"
fi

if [ ! -d "${SCRIPTS_PATH}" ];then
        mkdir -v "${SCRIPTS_PATH}"
        if [ "$?" -gt "0" ];then
                echo "Error creating: \"${SCRIPTS_PATH}\""
		echo "Creating LOCKFILE: \"${LOCK_FILE}\""
		rm -fv "${LOCK_FILE}"
                exit 1
        fi
fi

FIND_PATH="${SCRIPTS_PATH}"
CLISH_FILE_NAMES=$(find "${FIND_PATH}" -maxdepth 1 -type f  -regex '.*\.clish$' -exec bash -c 'grep -r "^##clish" $1 1> /dev/null && echo $1' _ {} \;; true)

if [ ! -z "${CLISH_FILE_NAMES}" ];then
count=0
while read -r file
do
	if [ ! -d "${ARCHIVE_PATH}/${START_EXECUTION_DATE}" ];then
		mkdir -p "${ARCHIVE_PATH}/${START_EXECUTION_DATE}"
	fi

        echo "Starting to work on: \"${file}\" at: $( date +"%Y_%m_%d_%H_%M_%SS" ) , Execution count: ${count}" |tee -a "${ARCHIVE_PATH}/${START_EXECUTION_DATE}/execution.log"
	echo "Starting to work on: \"${file}\" at: $( date +"%Y_%m_%d_%H_%M_%SS" ) , Execution count: ${count}" |logger
        clish -f "${file}"
	mv -v "${file}" "${ARCHIVE_PATH}/${START_EXECUTION_DATE}/${count}.clish_${START_EXECUTION_TIME}"
        echo "Finished working on: \"${file}\" , Exit Code: $? , at: $( date +"%Y_%m_%d_%H_%M_%SS" ) , Execution count: ${count}" |tee -a "${ARCHIVE_PATH}/${START_EXECUTION_DATE}/execution.log"
	echo "Finished working on: \"${file}\" , Exit Code: $? , at: $( date +"%Y_%m_%d_%H_%M_%SS" ) , Execution count: ${count}" |logger
	((count++))
done <<< "${CLISH_FILE_NAMES}"
fi

echo "Removing LOCKFILE: \"${LOCK_FILE}\""
rm -fv "${LOCK_FILE}"
EXIT_EXECUTION_TIME=$( date +"%Y_%m_%d_%H_%M_%SS" )
EXIT_EXECUTION_DATE=$( date +"%Y_%m_%d" )
echo "Finished Running: \"$0\"" |logger
