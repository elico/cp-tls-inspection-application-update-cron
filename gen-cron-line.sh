#!/usr/bin/env bash

function printTopHeader() {
	echo "####### NFGW Auto Genereated CRONS START MARK $(date)"
}

function printButtomHeader() {
	echo "####### NFGW Auto Genereated CRONS END MARK $(date)"
}

CA_CERT_BUNDLE_PATH="/pfrm2.0/opt/fw1/bin/ca-bundle.crt"
SSL_CERT_FILE="${CA_CERT_BUNDLE_PATH}"

export CA_CERT_BUNDLE_PATH
export SSL_CERT_FILE

GOGS_GIT_PREFIX=$( cat gogs_url_prefix )
GITHUB_GIT_PREFIX=$( cat github_url_prefix  )
GIT_PREFIX=""

if [ -f "use-gogs" ];then
	GIT_PREFIX="${GOGS_GIT_PREFIX}"
else
	GIT_PREFIX="${GITHUB_GIT_PREFIX}"
fi

DST_DOM_SCRIPT_URL="${GIT_PREFIX}/cron-example-with-diff-dstdom.sh"
DST_DOM_SCRIPT_MD5_SUM=$(md5sum cron-example-with-diff-dstdom.sh|awk '{print $1}')
DST_DOM_SCRIPT_PATH="/storage/cron-example-with-diff-dstdom.sh"
DST_SCRIPT_TMP_PATH="/tmp/cron-example-with-diff-dstdom.sh_73ffe3f6-b85a-46ed-9e11-07865339759c"

function createScriptUpdateCron() {
	SCRIPT_PATH="$1"
	SCRIPT_MD5_SUM="$2"
	SCRIPT_URL="$3"
	SCRIPT_TMP_PATH="$4"

	echo "#### Update Cron for the script: \"${SCRIPT_PATH}\""
	echo

	echo "*/5 * * * * (/usr/bin/md5sum ${SCRIPT_PATH} | /bin/grep \"^${SCRIPT_MD5_SUM} \") || (curl_cli --cacert ${CA_CERT_BUNDLE_PATH} -s ${SCRIPT_URL} -o ${SCRIPT_TMP_PATH} >/dev/null 2>&1 && /usr/bin/md5sum ${SCRIPT_TMP_PATH} |/bin/grep \"^${SCRIPT_MD5_SUM} \" && mv ${SCRIPT_TMP_PATH} ${SCRIPT_PATH} )"

	echo
	echo "####"
	echo
}

function createListUpdateCron() {
	SCRIPT_PATH="$1"
	APP_NAME="$2"
	DST_DOMAIN_LIST_URL="$3"

        echo "#### Update Cron for the FW APP: \"${APP_NAME}\""
        echo

	echo "*/5 * * * * su - admin -c \"/bin/bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL} >/dev/null 2>&1\""

	echo
        echo "####"
	echo
}

function createRunScriptAsCron() {
	USER="$1"
	SCRIPT_PATH="$2"
	ALLOW_STDOUT="$3"

        echo "#### Run Cron AS USER: ${USER}"
        echo
	
	if [ "${ALLOW_STDOUT}" -gt "0" ];then
		echo "*/30 * * * * su - ${USER} -c \"/bin/bash ${SCRIPT_PATH} >/dev/null 2>&1\""
	else
		echo "*/30 * * * * su - ${USER} -c \"/bin/bash ${SCRIPT_PATH}\""
	fi

	echo
        echo "####"
	echo
}

printTopHeader

createScriptUpdateCron "${DST_DOM_SCRIPT_PATH}" "${DST_DOM_SCRIPT_MD5_SUM}" "${DST_DOM_SCRIPT_URL}" "${DST_SCRIPT_TMP_PATH}"

COLLECT_CLISH_SCRIPT_PATH="/storage/collect-clish-scripts.sh"
COLLECT_CLISH_SCRIPT_MD5_SUM=$(md5sum collect-clish-scripts.sh|awk '{print $1}')

COLLECT_CLISH_SCRIPT_URL="${GIT_PREFIX}collect-clish-scripts.sh"
COLLECT_CLISH_SCRIPT_TMP_PATH="/tmp/collect-clish-scripts.sh_73ffe3f6-b85a-46ed-9e11-07865339759c"

createScriptUpdateCron  "${COLLECT_CLISH_SCRIPT_PATH}" "${COLLECT_CLISH_SCRIPT_MD5_SUM}" "${COLLECT_CLISH_SCRIPT_URL}" "${COLLECT_CLISH_SCRIPT_TMP_PATH}"

NgTechBypassDstDomain_APP_NAME="NgTechBypassDstDomain"
NgTechBypassDstDomain_LIST_URL=$( head -1 ngtech-bypass-dstdomains-list-url )

createListUpdateCron "${DST_DOM_SCRIPT_PATH}" "${NgTechBypassDstDomain_APP_NAME}" "${NgTechBypassDstDomain_LIST_URL}"

NgTechBlockListDstDomain_APP_NAME="NgTechBlockListDstDomain"
NgTechBlockListDstDomain_LIST_URL=$(head -1 block-list-dst-domain-url)

createListUpdateCron "${DST_DOM_SCRIPT_PATH}" "${NgTechBlockListDstDomain_APP_NAME}" "${NgTechBlockListDstDomain_LIST_URL}"

printButtomHeader
