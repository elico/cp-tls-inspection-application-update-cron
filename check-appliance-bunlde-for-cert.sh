#!/usr/bin/env bash

#/pfrm2.0/opt/fw1/database/ca_bundle.pem
#/pfrm2.0/config2/fw1/database/ca_bundle.pem

CERT_FILE="$1"
CACERT_FILE="$2"

if [ ! -f "${CERT_FILE}" ];then
	echo "${CERT_FILE} doesn't exist or not a file"
	exit 1
fi


if [ ! -f "${CACERT_FILE}" ];then
	echo "${CACERT_FILE} doesn't exist or not a file"
	exit 2
fi

CLEANED_CACERT=$( mktemp )
CLEANED_CERT_FILE=$( mktemp )

TMP_SINGLE_CERTS_DIR=$( mktemp -d )

cat "${CACERT_FILE}" | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${CLEANED_CACERT}"
cat "${CERT_FILE}" | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${CLEANED_CERT_FILE}"

cd ${TMP_SINGLE_CERTS_DIR} && \
        awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < "${CLEANED_CERT_FILE}"

FOUND_MATCH="0"

for cert in $(find ${TMP_SINGLE_CERTS_DIR}/ -type f -regex '.*.pem$' )
do
        diff -q "${CLEANED_CERT_FILE}" "${cert}" >/dev/null
        if [ "$?" -eq "0" ];then
                FOUND_MATCH="1"
                echo "Eureka: ${cert}"
                break
        fi
done

rm -v "${CLEANED_CACERT}"
rm -v "${CLEANED_CERT_FILE}"
rm -vf "${TMP_SINGLE_CERTS_DIR}"

if [ "${FOUND_MATCH}" -eq "1" ];then
        exit 0
else
        exit 1
fi
