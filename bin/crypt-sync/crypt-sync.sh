#!/bin/bash

while IFS="" read -r line || [ -n "$line" ]; do
    echo "${line}"
    cryptfile=$(cut -d' ' -f1 <<<"${line}")
    locfile=$(cut -d' ' -f2- <<<"${line}")
    #echo cryptfile=$cryptfile
    #echo locfile=$locfile

    if [ "${locfile}" -ot "${cryptfile}" ]; then
        #echo "$locfile -ot $cryptfile"
        echo "decrypting from vault"
        echo "sync'ing timestamp on files: touch -r ${cryptfile} ${locfile}"
    elif [ "$cryptfile" -ot "$locfile" ]; then
        #echo "$cryptfile -ot $locfile"
        echo "encrypting local file to vault"
        echo "sync'ing timestamp on files: touch -r ${locfile} ${cryptfile}"
    else
        echo "same date, leaving alone"
    fi
done < sync-list.txt
