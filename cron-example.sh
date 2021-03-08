#!/usr/bin/env bash

wget http://f-gogs.ngtech.home/NgTech-Home/tls-bypass-lists/raw/master/010-GeneralTLSInspectionBypass -O /tmp/010-GeneralTLSInspectionBypass

CURRENT_CONTENT=$(clish -c "show application application-name \"GeneralTLSInspectionBypass\""|egrep -v "^(description:|$|application-urls:|Categories:|application-id:|application-name:)" |awk '{print $1}')

function add_regex() {
        echo "$2"|grep -x -F "$1" >/dev/null
        RES="$?"

        if [ "${RES}" -eq "1" ];then
                if [ -f "/storage/regex-ready-appliance" ];then
                        echo "This appliance is ready to be used with regex"

                        echo -n "Adding regex: "
                        echo $1

# Some fixes are required for clish to be able to add EOL
#                       clish -c "set application application-name GeneralTLSInspectionBypass regex-url true add url $1"
                else
                        echo "This appliance is not ready to be used with Regex in cli"
                fi
        fi
}


while read line; do
        echo -n "Working on regex: "
        echo ${line}
        add_regex "${line}" "${CURRENT_CONTENT}"
done </tmp/010-GeneralTLSInspectionBypass

