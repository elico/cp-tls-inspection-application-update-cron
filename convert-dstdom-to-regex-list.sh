#!/usr/bin/env bash

FILENAME="$1"

function dstdomain_to_regex() {

	prefix="\."
	suffix="\."
	dot="\."
	dash="-"


	domain="$1"
	dstdomain="0"
	dotsuffix="0"

	echo "${domain}" | grep -e "^\." > /dev/null
	if [ "$?" -eq "0" ];then
		dstdomain=1
	fi

	echo "${domain}" | grep -e "\.$" > /dev/null
	if [ "$?" -eq "0" ];then
		dotsuffix=1
	fi

	case ${dstdomain} in
		1)
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\$/" -e 's/\\/\\\\/g'
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^[0-9a-zA-Z\\\-\\\.]+\\\.@g" -e "s/$/\\$/" -e 's/\\/\\\\/g'

			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\\.\\$/" -e 's/\\/\\\\/g'
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^[0-9a-zA-Z\\\-\\\.]+\\\.@g" -e "s/$/\\\\.\\$/" -e 's/\\/\\\\/g'

		;;
		*)
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\$/" -e 's/\\/\\\\/g'
			echo "${domain}" | sed -e "s/^${prefix}//" -e "s/${suffix}$//" -e "s/${dash}/\\\-/g" -e "s/${dot}/\\\./g" -e "s@^@\\^@g" -e "s/$/\\\.\\$/" -e 's/\\/\\\\/g'

		;;
	esac

}

while IFS= read -r line
do
	dstdomain_to_regex "${line}"
done < "${FILENAME}"
