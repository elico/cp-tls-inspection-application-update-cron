#!/usr/bin/env bash

SCRIPT_MD5_SUM=$(md5sum cron-example-with-diff-dstdom.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh"
DST_DOMAIN_LIST_URL="https://gist.githubusercontent.com/elico/249034a199d17ce52524f47fad49964f/raw/bdd95d87232f8173185acc14540d58bfb2c9ff79/010-GeneralTLSInspectionBypass.dstdom"
APP_NAME="NgTechBypassDstDomain"
SCRIPT_PATH="/storage/cron-example-with-diff-dstdom.sh"

echo "*/10 * * * * /usr/bin/wget -q ${SCRIPT_URL} -O ${SCRIPT_PATH}  >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && /bin/bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL} >/dev/null 2>&1"
