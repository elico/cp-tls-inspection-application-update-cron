#!/usr/bin/env bash

DEBUG="0"
DRY_RUN="0"
CLEANUP_AFTER="1"
REGEX_FLAG_ENABLED="0"
LOCK_FILE="/tmp/dst-domain-cron-lockfile"
FLAGS_PREFIX="/tmp/dst-dom-script-flag_"

if [ -f "${LOCK_FILE}" ];then
	echo "Lockfile exits, stopping update"
	exit 0
fi

touch "${LOCK_FILE}"

if [ -f "${FLAGS_PREFIX}debug" ];then
	DEBUG="1"
fi

if [ -f "${FLAGS_PREFIX}dry-run" ];then
	DRY_RUN="1"
fi

if [ -f "${FLAGS_PREFIX}cleanup-after" ];then
	CLEANUP_AFTER="1"
fi

if [ -f "${FLAGS_PREFIX}dont-cleanup-after" ];then
	CLEANUP_AFTER="0"
fi

if [ -f "${FLAGS_PREFIX}add-regex-flag" ];then
	REGEX_FLAG_ENABLED="1"
fi

function dstdomain_to_regex() {

	prefix="\."
	suffix="\."
	dot="\."
	dash="-"


	domain="$1"
	dstdomain="0"
	dotsuffix="0"

	echo "${domain}" | grep -e "^\." > /dev/null
	if [ "$?" -eq "0" ];then
		dstdomain=1
	fi

	echo "${domain}" | grep -e "\.$" > /dev/null
	if [ "$?" -eq "0" ];then
		dotsuffix=1
	fi

	case ${dstdomain} in
		1)
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\$/"
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^[0-9a-zA-Z\\\-\\\.]+\\\.@g" -e "s/$/\\$/"

			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\\.\\$/"
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^[0-9a-zA-Z\\\-\\\.]+\\\.@g" -e "s/$/\\\\.\\$/"

		;;
		*)
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\$/"
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\\.\\$/"

		;;
	esac

}



APP_NAME="$1"
URL="$2"

if [ -f "dst-domain-url" ];then
	echo "Overriding URL with a local dst-domain-url file"
	DST_DOM_URL_FILE_SIZE=$(cat dst-domain-url |wc -l)
	if [ "${DST_DOM_URL_FILE_SIZE}" -gt "0" ];then
		URl=$( head -n1 dst-domain-url )
	else
		echo "dst-domain-url is empty"
	        exit 1
	fi
fi

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

TMP_DIFF_FILE=$( mktemp )

clish -c "show configuration"|egrep "^set application application-name \"${APP_NAME}\"" > ${TMP_CURRENT_CONFIG_FILE}

CURRENT_APP_CONTENT=$( cat ${TMP_CURRENT_CONFIG_FILE}| awk 'BEGIN { FS = " add url " } ; { print $2}' )

while IFS= read -r line
do
        if [ "${DEBUG}" -gt "0" ];then
                echo -n "DEBUG LEVEL 1: Working on dstdomain: " >&2
                echo "${line}" >&2
        fi

	dstdomain_to_regex_result="$(dstdomain_to_regex ${line})"
	while IFS= read -r regex; do
	        echo "${CURRENT_APP_CONTENT}"|  grep -x -F "${regex}" >/dev/null
	        RES=$?

	       if [ "${RES}" -gt "0" ];then
		       if [ "${REGEX_FLAG_ENABLED}" -eq "1" ];then
	        	       echo "set application application-name \"${APP_NAME}\" regex-url true add url \"${regex}\"" >> ${TMP_CLISH_UPDATE_FILE}
		       else
		               echo "set application application-name \"${APP_NAME}\" add url \"${regex}\"" >> ${TMP_CLISH_UPDATE_FILE}
		       fi
        	fi

	done <<< "${dstdomain_to_regex_result}"


done < ${TMP_DOWNLOAD_FILE}

cat "${TMP_CURRENT_CONFIG_FILE}" |sort > "${TMP_CURRENT_CONFIG_FILE}.in"
mv -v -f "${TMP_CURRENT_CONFIG_FILE}.in" "${TMP_CURRENT_CONFIG_FILE}" 

cat "${TMP_CLISH_UPDATE_FILE}" |sort |uniq > "${TMP_CLISH_UPDATE_FILE}.in"
mv -v -f "${TMP_CLISH_UPDATE_FILE}.in" "${TMP_CLISH_UPDATE_FILE}"

DIFF=$(diff "${TMP_CURRENT_CONFIG_FILE}" "${TMP_CLISH_UPDATE_FILE}" )
echo "DIFF CMD: diff ${TMP_CURRENT_CONFIG_FILE} ${TMP_CLISH_UPDATE_FILE}"
echo "${DIFF}" > "${TMP_DIFF_FILE}"

if [ "${DEBUG}" -gt "0" ];then
        echo "DIFF Size: $(echo "${DIFF}"|wc -l)"
        echo "${DIFF}"
fi

DELETE_OBJECTS=$(echo "${DIFF}" |egrep "^-set " |awk '{print $7}')

for object in ${DELETE_OBJECTS}; do
#	LOCAL_OBJECT=$( echo ${object}| sed -e "s@\.@\\\.@g" -e "s@\-@\\\-@g" -e "s@\_@\\\_@g" )
        echo "set application application-name \"${APP_NAME}\" remove url ${object}" >> ${TMP_CLISH_TRANSACTION_FILE}
#        echo "set application application-name \"${APP_NAME}\" remove url ${LOCAL_OBJECT}" >> ${TMP_CLISH_TRANSACTION_FILE}
done

echo "${DIFF}" |egrep "^\+set " |sed -e "s@^\+set @set @g" >>  ${TMP_CLISH_TRANSACTION_FILE}

#cat "${TMP_CLISH_TRANSACTION_FILE}"

sed -i -e 's@\\@\\\\\\@g' "${TMP_CLISH_TRANSACTION_FILE}"

if [ "${DRY_RUN}" -eq "0" ];then
        clish -f "${TMP_CLISH_TRANSACTION_FILE}"
fi

echo "Finished Transaction"
echo "Cleaning up files ..."

if [ "${CLEANUP_AFTER}" -eq "1" ];then
        rm -v "${TMP_DOWNLOAD_FILE}"
        rm -v "${TMP_CLISH_UPDATE_FILE}"
        rm -v "${TMP_CURRENT_CONFIG_FILE}"
        rm -v "${TMP_DIFF_FILE}"
        rm -v "${TMP_CLISH_TRANSACTION_FILE}"

else
        echo "Don't forget to cleanup the files:"
        echo "${TMP_DOWNLOAD_FILE}"
        echo "${TMP_CLISH_UPDATE_FILE}"
        echo "${TMP_CURRENT_CONFIG_FILE}"
        echo "${TMP_DIFF_FILE}"
        echo "${TMP_CLISH_TRANSACTION_FILE}"
fi

rm -fv "${LOCK_FILE}"
