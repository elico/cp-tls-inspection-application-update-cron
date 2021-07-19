#!/usr/bin/env bash

CRON_FILE="/pfrm2.0/etc/crontabs/root"

sed -i -n '/^####### NFGW Auto Genereated CRONS START MARK/{p; :a; N; /####### NFGW Auto Genereated CRONS END MARK/!ba; s/.*\n//}; p' |sed -e "s@^####### NFGW Auto Genereated CRONS START MARK.*@@g" -e "s@^####### NFGW Auto Genereated CRONS END MARK.*@@g" "${CRON_FILE}"
