#!/bin/bash

## Using https://github.com/baruchel/txt2pdf to print emails to PDF with unicode support. 

pdir="$HOME/Sync/EmailAttachments/Emails" 
open_pdf=evince 
scriptloc="python3 $HOME/bin/txt2pdf.py"
date_str=`date +"%Y-%m-%d_T%H-%M-%S%Z"`

# check to make sure that we're looking for txt2pdf in the right place 
if ! command -v python3 $scriptloc  >/dev/null; then
    echo "Is $scriptloc installed?"
    exit 1
fi
	
# create temp dir if it does not exist
if [ ! -d "$pdir" ]; then
    mkdir -p "$pdir" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Unable to make directory '$pdir'" 1>&2
        exit 2
    fi
fi

# dump stdin to a tempfile
tmptxt="`mktemp $XDG_CACHE_HOME/mutt_XXXXXXX.txt`"
cat >> $tmptxt

pdffile="`$pdir/$date_str.pdf`" 

# Actually write the text into a PDF. 
$scriptloc -o $pdffile $tmptxt
# TODO check for graphical environment before opening evince
$open_pdf $pdffile >/dev/null 2>&1 &
sleep 1
#rm $pdffile
rm $tmptxt
