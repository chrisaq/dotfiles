#!/usr/bin/env bash

set -e

function usage_info {
    echo "usage: $0 <ROMLIST> <ROMDIR> <FILE SUFFIX>"
    echo "example: $0 allkiller.txt /mnt/Storage/Software/EmulatorSets/MAME/roms-0.78 zip"
    exit
}


if test "$#" -ne 3; then
    echo "Script requires 3 parameters" >&2
    usage_info $0
    exit
fi

echo script: $0
echo arg1: $1
echo arg2: $2
echo arg3: $3

ROMLIST=$1
ROMDIR=$2
SUFFIX=$3

if test ! -f "${ROMLIST}"; then
    echo "File ${ROMLIST} does not exist" >&2
    exit
fi

if test ! -d "${ROMDIR}"; then
    echo "Directory ${ROMDIR} does not exist" >&2
    exit
fi


OLDIFS=$IFS
IFS=$'\n'
for rom in $(cat ${ROMLIST});
do
    #echo "${rom}"
    #echo "${ROMDIR}/${rom}.${SUFFIX}"
    if test -f "${ROMDIR}/${rom}.${SUFFIX}"; then
        echo ln -s "${ROMDIR}/${rom}.${SUFFIX}" "${rom}.${SUFFIX}"
        ln -s "${ROMDIR}/${rom}.${SUFFIX}" "${rom}.${SUFFIX}"
    fi
done
IFS=$OLDIFS

