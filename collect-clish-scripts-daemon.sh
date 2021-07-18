#!/usr/bin/env bash

URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/collect-clish-scripts.sh"

CURRENT_ETAG=""
LOCAL_MD5=""
REMOTE_MD5=""
EXPECTED_MD5="dd0618772ee09cfe8c3cc7a0574d4a3f"
#AUTO_FETCH_URL="0"

FILENAME="/storage/collect-clish-scripts.sh"

which curl_cli >/dev/null 2>&1 && CURL="curl_cli"
which curl >/dev/null 2>&1 && CURL="curl"

while true
do

	LOCAL_MD5=$( md5sum "${FILENAME}" |awk '{print $1}' )
	if [ ! -z "${EXPECTED_MD5}" ];then
		if [ "${LOCAL_MD5}" == "${EXPECTED_MD5}" ]; then
		        /bin/bash /storage/collect-clish-scripts.sh >/dev/null 2>&1
			sleep 5
			continue
		fi
	else
		REMOTE_ETAG=$(${CURL} -k -s -I "${URL}" |grep "Etag" -i |head -1 |awk '{print $2}'|sed -e "s@\"@@")
		if [ "${CURRENT_ETAG}" != "${REMOTE_ETAG}" ];then
		        /usr/bin/wget -q "${URL}" -O "${FILENAME}.in"
		        REMOTE_MD5=$( md5sum "${FILENAME}.in" |awk '{print $1}' )
		fi
		
		if [ "${LOCAL_ETAG}" != "${REMOTE_ETAG}" ];then
		        CURRENT_ETAG="${REMOTE_ETAG}"
		        if [ "${REMOTE_MD5}" != "${LOCAL_MD5}" ]; then
		                mv "${FILENAME}.in" "${FILENAME}"
		                LOCAL_MD5="${REMOTE_MD5}"
		        fi
		fi
	
		/bin/bash /storage/collect-clish-scripts.sh >/dev/null 2>&1
	
		sleep 5
	fi
done
