#!/usr/bin/env bash

DEBUG="0"
DRY_RUN="0"
CLEANUP_AFTER="1"
REGEX_FLAG_ENABLED="0"

APP_NAME="$1"

URL="https://gist.githubusercontent.com/elico/249034a199d17ce52524f47fad49964f/raw/94d4c90614a9eddfb5d0b8c01f3d636ddb3909da/010-GeneralTLSInspectionBypass"

if [ -z "${APP_NAME}" ];then
        echo "Missing App Name"
        exit 1
fi

if [ "$2" == "check" ];then
        DRY_RUN="1"
        echo "Running in dry run mode" >&2
fi

if [ ! -z "$3" ];then
        URL="$3"
fi

TMP_DOWNLOAD_FILE=$(mktemp)

wget "${URL}" -O ${TMP_DOWNLOAD_FILE}
RES=$?

if [ "${RES}" -gt "0" ];then
        echo "Error Downloading file from URL: \"${URL}\""
        rm -v "${TMP_DOWNLOAD_FILE}"
        exit ${RES}
fi

TMP_CLISH_UPDATE_FILE=$( mktemp )

TMP_CURRENT_CONFIG_FILE=$( mktemp )

TMP_CLISH_TRANSACTION_FILE=$( mktemp )

clish -c "show configuration"|egrep "^set application application-name \"${APP_NAME}\"" > ${TMP_CURRENT_CONFIG_FILE}

CURRENT_APP_CONTENT=$( cat ${TMP_CURRENT_CONFIG_FILE}| awk '{print $7}' )

while IFS= read -r line
do
        if [ "${DEBUG}" -gt "0" ];then
                echo -n "DEBUG LEVEL 1: Working on regex: " >&2
                echo "${line}" >&2
        fi
        echo "${CURRENT_APP_CONTENT}"|  grep -x -F "${line}" >/dev/null
        RES=$?

        if [ "${RES}" -gt "0" ];then
	       if [ "${REGEX_FLAG_ENABLED}" -eq "1" ];then
        	       echo "set application application-name \"${APP_NAME}\" regex-url true add url \"${line}\"" >> ${TMP_CLISH_UPDATE_FILE}
	       else
	               echo "set application application-name \"${APP_NAME}\" add url \"${line}\"" >> ${TMP_CLISH_UPDATE_FILE}
	       fi
        fi

done < ${TMP_DOWNLOAD_FILE}

DIFF=$(diff "${TMP_CURRENT_CONFIG_FILE}" "${TMP_CLISH_UPDATE_FILE}" )

if [ "${DEBUG}" -gt "0" ];then
        echo "DIFF Size: $(echo "${DIFF}"|wc -l)"
        echo "${DIFF}"
fi

DELETE_OBJECTS=$(echo "${DIFF}" |egrep "^-set " |awk '{print $7}')

for object in ${DELETE_OBJECTS}; do
        echo "set application application-name \"${APP_NAME}\" remove url ${object}" >> ${TMP_CLISH_TRANSACTION_FILE}
done

echo "${DIFF}" |egrep "^\+set " |sed -e "s@^\+set @set @g" >>  ${TMP_CLISH_TRANSACTION_FILE}

cat "${TMP_CLISH_TRANSACTION_FILE}"

if [ "${DRY_RUN}" -eq "0" ];then
        clish -f "${TMP_CLISH_TRANSACTION_FILE}"
fi

echo "Finished Transaction"
echo "Cleaning up files ..."

if [ "${CLEANUP_AFTER}" -eq "1" ];then
        rm -v "${TMP_DOWNLOAD_FILE}"
        rm -v "${TMP_CLISH_UPDATE_FILE}"
        rm -v "${TMP_CURRENT_CONFIG_FILE}"
        rm -v "${TMP_CLISH_TRANSACTION_FILE}"
else
        echo "Don't forget to cleanup the files:"
        echo "${TMP_DOWNLOAD_FILE}"
        echo "${TMP_CLISH_UPDATE_FILE}"
        echo "${TMP_CURRENT_CONFIG_FILE}"
        echo "${TMP_CLISH_TRANSACTION_FILE}"
fi

