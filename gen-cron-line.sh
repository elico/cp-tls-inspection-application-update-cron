#!/usr/bin/env bash

SCRIPT_MD5_SUM=$(md5sum cron-example-with-diff-dstdom.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh"
DST_DOMAIN_LIST_URL=$(head -1 dst-domain-url)
APP_NAME="NgTechBypassDstDomain"
SCRIPT_PATH="/storage/cron-example-with-diff-dstdom.sh"

export CA_CERT_BUNDLE_PATH="/pfrm2.0/opt/fw1/bin/ca-bundle.crt"
export SSL_CERT_FILE="${CA_CERT_BUNDLE_PATH}"
alias curl_cli="curl_cli --cacert ${CA_CERT_BUNDLE_PATH}"


echo "####"
echo

SCRIPT_TMP_PATH="/tmp/cron-example-with-diff-dstdom.sh_73ffe3f6-b85a-46ed-9e11-07865339759c"
echo "*/5 * * * * /usr/bin/md5sum ${SCRIPT_PATH} | /bin/grep \"^${SCRIPT_MD5_SUM} \" || curl_cli --cacert ${CA_CERT_BUNDLE_PATH} -s ${SCRIPT_URL} -o ${SCRIPT_TMP_PATH} >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_TMP_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && mv ${SCRIPT_TMP_PATH} ${SCRIPT_PATH}"


echo "####"
echo
echo "*/5 * * * * /bin/bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL} >/dev/null 2>&1"

echo "####"
echo


DST_DOMAIN_LIST_URL=$(head -1 block-list-dst-domain-url)
APP_NAME="NgTechBlockListDstDomain"
echo "*/1 * * * * bin/bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL} >/dev/null 2>&1"


SCRIPT_MD5_SUM=$(md5sum collect-clish-scripts.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/collect-clish-scripts.sh"
SCRIPT_PATH="/storage/collect-clish-scripts.sh"
SCRIPT_TMP_PATH="/tmp/collect-clish-scripts.sh_73ffe3f6-b85a-46ed-9e11-07865339759c"

echo "####"
echo

echo "*/5 * * * * /usr/bin/md5sum ${SCRIPT_PATH} | /bin/grep \"^${SCRIPT_MD5_SUM} \" || curl_cli --cacert ${CA_CERT_BUNDLE_PATH} -s ${SCRIPT_URL} -o ${SCRIPT_TMP_PATH} >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_TMP_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && mv ${SCRIPT_TMP_PATH} ${SCRIPT_PATH}"

echo "####"
echo

echo "*/30 * * * * /bin/bash ${SCRIPT_PATH} >/dev/null 2>&1"
