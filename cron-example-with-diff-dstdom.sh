#!/usr/bin/env bash

DEBUG="0"
DRY_RUN="1"
CLEANUP_AFTER="1"
REGEX_FLAG_ENABLED="0"

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

URL="https://gist.githubusercontent.com/elico/249034a199d17ce52524f47fad49964f/raw/bdd95d87232f8173185acc14540d58bfb2c9ff79/010-GeneralTLSInspectionBypass.dstdom"

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
