#!/bin/bash

for syncfile in `ls ${HOME}/bin/crypt-sync/crypt-sync-list*.txt`; do

    while IFS="" read -r line || [ -n "$line" ]; do
        echo "${line}"
        cryptfile=$(cut -d':' -f1 <<<"${line}")
        locfile=$(cut -d':' -f2- <<<"${line}")
        cryptfile=${HOME}/Sync/Password-Store/ConfigFiles/${cryptfile}
        locfile=${HOME}/${locfile}
        #echo cryptfile=$cryptfile
        #echo locfile=$locfile

        # Config file on machine older than encrypted file in Password-Store.
        # Replacing config file by decrypting newer file.
        if [ "${locfile}" -ot "${cryptfile}" ]; then
            #echo "$locfile -ot $cryptfile"
            echo "Decrypting from vault to config file"
            ls -la ${locfile}
            ls -la ${cryptfile}
            gpg --yes --output ${locfile} --decrypt ${cryptfile}
            #echo "sync'ing timestamp on files: touch -r ${cryptfile} ${locfile}"
            touch -r ${cryptfile} ${locfile}
        # Encrypted file in Password-Store older than config file.
        # Encrypting newer config file to Password-Store.
        elif [ "$cryptfile" -ot "$locfile" ]; then
            #echo "$cryptfile -ot $locfile"
            echo "Encrypting local file to vault"
            ls -la ${locfile}
            ls -la ${cryptfile}
            gpg --yes --encrypt --sign --armor --recipient 0xAEE3FD309AFCC09E --output ${cryptfile} ${locfile}
            #echo "sync'ing timestamp on files: touch -r ${locfile} ${cryptfile}"
            touch -r ${locfile} ${cryptfile}
        else
            echo "Same date, leaving alone"
        fi


    done < ${syncfile}
    #done < ${HOME}/bin/crypt-sync/crypt-sync-list.txt

done
