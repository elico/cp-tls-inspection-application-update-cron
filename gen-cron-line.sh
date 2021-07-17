#!/usr/bin/env bash

SCRIPT_MD5_SUM=$(md5sum cron-example-with-diff-dstdom.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh"
DST_DOMAIN_LIST_URL=$(head -1 dst-domain-url)
APP_NAME="NgTechBypassDstDomain"
SCRIPT_PATH="/storage/cron-example-with-diff-dstdom.sh"

echo "*/10 * * * * /usr/bin/wget -q ${SCRIPT_URL} -O ${SCRIPT_PATH}  >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && /bin/bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL} >/dev/null 2>&1"


SCRIPT_MD5_SUM=$(md5sum collect-clish-scripts.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/collect-clish-scripts.sh"
SCRIPT_PATH="/storage/collect-clish-scripts.sh"

echo "*/10 * * * * /usr/bin/wget -q ${SCRIPT_URL} -O ${SCRIPT_PATH}  >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && /bin/bash ${SCRIPT_PATH} >/dev/null 2>&1"
