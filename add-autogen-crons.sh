#!/usr/bin/env bash

CRON_FILE="/pfrm2.0/etc/crontabs/root"

bash remove-autogen-crons.sh

bash gen-cron-line.sh |tee -a "${CRON_FILE}" >/dev/null
