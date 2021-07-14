#!/usr/bin/env bash

SCRIPT_MD5_SUM=$(md5sum cron-example-with-diff-dstdom.sh|awk '{print $1}')
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh"
DST_DOMAIN_LIST_URL=$(head -1 dst-domain-url)
APP_NAME="NgTechBypassDstDomain"
SCRIPT_PATH="/storage/cron-example-with-diff-dstdom.sh"

echo -e "#!/usr/bin/env bash\nwget ${SCRIPT_URL} \\
	-O ${SCRIPT_PATH} && \\
	md5sum ${SCRIPT_PATH} | grep \"^${SCRIPT_MD5_SUM} \" && \\
	bash ${SCRIPT_PATH} ${APP_NAME} ${DST_DOMAIN_LIST_URL}"
