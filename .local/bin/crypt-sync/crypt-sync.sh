#!/bin/bash

for syncfile in "${XDG_BIN_HOME}"/crypt-sync/crypt-sync-list*.txt; do
    [ -e "$syncfile" ] || continue

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
        esac
        echo "$line"
        cryptfile=${line%%:*}
        locfile=${line#*:}
        if [ "$cryptfile" = "$line" ] || [ -z "$cryptfile" ] || [ -z "$locfile" ]; then
            echo "Skipping malformed line: $line"
            continue
        fi
        cryptfile="${HOME}/Sync/Password-Store/ConfigFiles/${cryptfile}"
        locfile="${HOME}/${locfile}"
        cryptdir=$(dirname "$cryptfile")
        locdir=$(dirname "$locfile")
        #echo cryptfile=$cryptfile
        #echo locfile=$locfile

        if [ ! -e "$cryptfile" ] && [ ! -e "$locfile" ]; then
            echo "Missing both files, skipping"
            continue
        fi

        # Config file on machine older than encrypted file in Password-Store.
        # Replacing config file by decrypting newer file.
        if [ ! -e "$locfile" ] && [ -e "$cryptfile" ]; then
            mkdir -p "$locdir"
            echo "Decrypting from vault to config file"
            ls -la "$cryptfile"
            gpg --yes --output "$locfile" --decrypt "$cryptfile"
            #echo "sync'ing timestamp on files: touch -r ${cryptfile} ${locfile}"
            touch -r "$cryptfile" "$locfile"
        elif [ ! -e "$cryptfile" ] && [ -e "$locfile" ]; then
            mkdir -p "$cryptdir"
            echo "Encrypting local file to vault"
            ls -la "$locfile"
            # Removing --sign stops gpg from asking for passphrase for every changed file.
            gpg --yes --encrypt --armor --recipient 0xAEE3FD309AFCC09E --output "$cryptfile" "$locfile"
            #echo "sync'ing timestamp on files: touch -r ${locfile} ${cryptfile}"
            touch -r "$locfile" "$cryptfile"
        elif [ "$locfile" -ot "$cryptfile" ]; then
            if [ ! -d "$locdir" ]; then
                mkdir -p "$locdir"
            fi
            #echo "$locfile -ot $cryptfile"
            echo "Decrypting from vault to config file"
            ls -la "$locfile"
            ls -la "$cryptfile"
            gpg --yes --output "$locfile" --decrypt "$cryptfile"
            #echo "sync'ing timestamp on files: touch -r ${cryptfile} ${locfile}"
            touch -r "$cryptfile" "$locfile"
        # Encrypted file in Password-Store older than config file.
        # Encrypting newer config file to Password-Store.
        elif [ "$cryptfile" -ot "$locfile" ]; then
            if [ ! -d "$cryptdir" ]; then
                mkdir -p "$cryptdir"
            fi
            #echo "$cryptfile -ot $locfile"
            echo "Encrypting local file to vault"
            ls -la "$locfile"
            ls -la "$cryptfile"
            # Removing --sign stops gpg from asking for passphrase for every changed file.
            gpg --yes --encrypt --armor --recipient 0xAEE3FD309AFCC09E --output "$cryptfile" "$locfile"
            #echo "sync'ing timestamp on files: touch -r ${locfile} ${cryptfile}"
            touch -r "$locfile" "$cryptfile"
        else
            echo "Same date, leaving alone"
        fi


    done < "$syncfile"
    #done < ${HOME}/bin/crypt-sync/crypt-sync-list.txt

done
