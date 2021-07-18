#!/usr/bin/env bash

SCRIPT_MD5_SUM=$( md5sum collect-clish-scripts-daemon.sh |awk '{print $1}' )
SCRIPT_URL="https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/collect-clish-scripts-daemon.sh"
SCRIPT_PATH="/storage/collect-clish-scripts-daemon.sh"
USERSCRIPT_PATH="/pfrm2.0/etc/userScript"

echo -e "#!/usr/bin/env bash

logger \"Starting /pfrm2.0/etc/userScript\"
wget ${SCRIPT_URL} \\
        -O ${SCRIPT_PATH} && \\
        md5sum ${SCRIPT_PATH} | grep \"^${SCRIPT_MD5_SUM} \" >/dev/null && \\
        bash ${SCRIPT_PATH} &
logger \"Exiting /pfrm2.0/etc/userScript\"" 
