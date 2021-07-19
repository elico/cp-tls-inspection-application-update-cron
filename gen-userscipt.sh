#!/usr/bin/env bash

SCRIPT_MD5_SUM=$( md5sum collect-clish-scripts-daemon.sh |awk '{print $1}' )

GOGS_GIT_PREFIX=$( cat gogs_url_prefix )
GITHUB_GIT_PREFIX=$( github_url_prefix  )

if [ -f "use-gogs" ];then
	SCRIPT_URL="${GOGS_GIT_PREFIX}collect-clish-scripts-daemon.sh"
else
	SCRIPT_URL="${GITHUB_GIT_PREFIX}collect-clish-scripts-daemon.sh"
fi

SCRIPT_PATH="/storage/collect-clish-scripts-daemon.sh"
USERSCRIPT_PATH="/pfrm2.0/etc/userScript"
LOCK_FILE="/tmp/clish-scripts-collector-cron-lockfile"

echo -e "#!/usr/bin/env bash

logger \"Starting /pfrm2.0/etc/userScript\"

rm -f -v "${LOCK_FILE}"

wget ${SCRIPT_URL} \\
        -O ${SCRIPT_PATH} && \\
        md5sum ${SCRIPT_PATH} | grep \"^${SCRIPT_MD5_SUM} \" >/dev/null && \\
        bash ${SCRIPT_PATH} $(date|md5sum |awk '{print $1}')>/dev/null 2>&1 &
logger \"Exiting /pfrm2.0/etc/userScript\"" 
