#!/usr/bin/env bash

APP_NAME="$1"

clish -c "show application application-name \"${APP_NAME}\"" | sed -e "s@^description.*@@g" \
	-e "s@^application\-name\:.*@@g" \
	-e "s@^application\-id\:.*@@g" \
	-e "s@^Categories\:.*@@g" \
	-e "s@^application\-urls\:@@g" \
	-e 's@^[ \t]\+@@g' \
	-e '/^$/ d'
