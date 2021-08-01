#!/usr/bin/env bash

FLAGS_PREFIX="/tmp/dst-dom-script-flag_"
WORK_DIR="/tmp/dst-dom-script"

mkdir -vp "${WORK_DIR}"
cd "${WORK_DIR}"

export CPDIR=/opt/fw1
export FWDIR=${CPDIR}
export SUROOT=/var/suroot
. /pfrm2.0/etc/bashrc

if [ "$( pt users -f username $USER -F role | head -n 1 | grep -v {} )" != "ROLE.SUPER" ];then
	  echo "This script can only run from a user with ROLE.SUPER ie super user"
	  exit 1
fi


if [ -f "${FLAGS_PREFIX}unsetx" ];then
        set -x
fi

DEBUG="0"
DRY_RUN="0"
CLEANUP_AFTER="1"
REGEX_FLAG_ENABLED="0"
LOCK_FILE="/tmp/dst-domain-cron-lockfile"
DUMP_ENV="/tmp/env_cd5fecd5-7123-4a21-bd02-242f1d695a6d"

CA_CERT_BUNDLE_PATH="/pfrm2.0/opt/fw1/bin/ca-bundle.crt"
SSL_CERT_FILE="${CA_CERT_BUNDLE_PATH}"

if [ -f "${LOCK_FILE}" ];then
        echo "Lockfile \"${LOCK_FILE}\" exits, stopping update"
        exit 0
fi

touch "${LOCK_FILE}"

if [ -f "${FLAGS_PREFIX}debug" ];then
        DEBUG="1"
fi

if [ -f "${FLAGS_PREFIX}dry-run" ];then
        DRY_RUN="1"
        echo "Runnning dry run"
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

if [ -f "${FLAGS_PREFIX}dump-env" ];then
        env |tee "${DUMP_ENV}"
        export | tee -a "${DUMP_ENV}"
fi

function dstdomain_to_regex() {

        prefix="\."
        suffix="\."
        dot="\."
        dash="-"


        domain="$1"
        dstdomain="0"
        dotsuffix="0"

        if [ -z "${domain}" ];then
                return
        fi

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

/opt/fw1/bin/curl_cli -s --cacert "${SSL_CERT_FILE}" "${URL}" -o "${TMP_DOWNLOAD_FILE}" >> /tmp/log.1
RES="$?"
if [ "${RES}" -gt "0" ];then
        echo "Error Downloading file from URL: \"${URL}\""
        logger "Error Downloading file from URL: \"${URL}\""
        rm -v "${TMP_DOWNLOAD_FILE}"
        rm -fv "${LOCK_FILE}"
        exit ${RES}
fi

TMP_CLISH_UPDATE_FILE=$( mktemp )

TMP_CURRENT_CONFIG_FILE=$( mktemp )

TMP_CLISH_TRANSACTION_FILE=$( mktemp )

TMP_DIFF_FILE=$( mktemp )

TMP_CURRENT_APP_CONTENT_FILE=$( mktemp )

APP_DETAILS=$( clish -c "show application application-name ${APP_NAME}" )
echo "$? exit code from clish -c \"show application application-name ${APP_NAME}\""

echo "${APP_DETAILS}" | sed -e "s@^description.*@@g" \
        -e "s@.*Role\ is\ not\ assigned\ to\ user.*@@g" \
        -e "s@^application\-name\:.*@@g" \
        -e "s@^application\-id\:.*@@g" \
        -e "s@^Categories\:.*@@g" \
        -e "s@^application\-urls\:@@g" \
        -e 's@^[ \t]\+@@g' \
        -e '/^$/ d' > ${TMP_CURRENT_APP_CONTENT_FILE}

CURRENT_APP_CONTENT_REGEX=$( cat "${TMP_CURRENT_APP_CONTENT_FILE}" |sort )
REMOTE_APP_CONTENT_REGEX=$( mktemp )
echo "${CURRENT_APP_CONTENT_REGEX}" > "${TMP_CURRENT_APP_CONTENT_FILE}"

comp_start=`date +%s`
echo "Compiling APP_REGEX started at: ${comp_start}"

while IFS= read -r line
do
        if [ "${DEBUG}" -gt "0" ];then
                echo -n "DEBUG LEVEL 1: Working on dstdomain: " >&2
                echo "${line}" >&2
        fi

        dstdomain_to_regex_result="$(dstdomain_to_regex ${line})"
        echo "${dstdomain_to_regex_result}" |tee -a "${REMOTE_APP_CONTENT_REGEX}" >/dev/null

done < ${TMP_DOWNLOAD_FILE}

comp_end=`date +%s`
comp_runtime=$( echo "$comp_end - $comp_start" | bc -l )

echo "FINISHED Compiling APP_REGEX finished at: ${comp_end} , Took: ${comp_runtime} Seconds"

SORTED_REMOTE_APP_CONTENT_REGEX=$( cat "${REMOTE_APP_CONTENT_REGEX}" | sort| uniq )
echo "${SORTED_REMOTE_APP_CONTENT_REGEX}" > "${REMOTE_APP_CONTENT_REGEX}"

DIFF=$( diff "${TMP_CURRENT_APP_CONTENT_FILE}" "${REMOTE_APP_CONTENT_REGEX}" |sed -e "1,3d;" )
echo "DIFF CMD: diff ${TMP_CURRENT_APP_CONTENT_FILE} ${REMOTE_APP_CONTENT_REGEX} | sed -e \"1,3d;\""

##
DELETE_OBJECTS=$( echo "${DIFF}" |egrep "^\-" |sed -e "s@^\-@@")

for object in ${DELETE_OBJECTS}; do
        echo "set application application-name \"${APP_NAME}\" remove url ${object}" >> ${TMP_CLISH_TRANSACTION_FILE}
done

APPEND_OBJECTS=$( echo "${DIFF}" |egrep "^\+" |sed -e "s@^\+@@")

for object in ${APPEND_OBJECTS}; do
        echo "set application application-name \"${APP_NAME}\" add url ${object}" >> ${TMP_CLISH_TRANSACTION_FILE}
done
##

sed -i -e 's@\\@\\\\\\@g' "${TMP_CLISH_TRANSACTION_FILE}"

if [ "${DRY_RUN}" -eq "0" ];then
        clish -i -f "${TMP_CLISH_TRANSACTION_FILE}"
        echo "$? exit code from clish -f"
else
        echo "Running in DRY-RUN MODE"
fi

echo "Finished Transaction"
echo "Cleaning up files ..."

if [ "${CLEANUP_AFTER}" -eq "1" ];then
        rm -v "${TMP_DOWNLOAD_FILE}"
        rm -v "${TMP_CLISH_UPDATE_FILE}"
        rm -v "${TMP_CURRENT_APP_CONTENT_FILE}"
        rm -v "${REMOTE_APP_CONTENT_REGEX}"
        rm -v "${TMP_CURRENT_CONFIG_FILE}"
        rm -v "${TMP_DIFF_FILE}"
        rm -v "${TMP_CLISH_TRANSACTION_FILE}"

else
        echo "Don't forget to cleanup the files:"
        echo "${TMP_DOWNLOAD_FILE}"
        echo "${TMP_CLISH_UPDATE_FILE}"
        echo "${TMP_CURRENT_APP_CONTENT_FILE}"
        echo  "${REMOTE_APP_CONTENT_REGEX}"
        echo "${TMP_CURRENT_CONFIG_FILE}"
        echo "${TMP_DIFF_FILE}"
        echo "${TMP_CLISH_TRANSACTION_FILE}"
fi

rm -fv "${LOCK_FILE}"

logger "Finished running a dstdomain update for: APP => \"${APP_NAME}\" , from URL => \"${URL}\""

set +x
