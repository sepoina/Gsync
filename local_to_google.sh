#!/bin/bash
#######################################################################################################################
# gsync0.2 - febbraio 2021
# rclone version from
# https://beta.rclone.org/branch/fix-rmdirs-filter/v1.55.0-beta.5165.358c0832c.fix-rmdirs-filter/
#
# A-Source <---- bisync ---> B-Destination
# local: <- for local directory
#
#######################################################################################################################
source "bin/gsync.sh"
# two dir for bisync
directory_A="local:/mnt/Laboratorio/L/Backup/googlezita"
directory_B="googlezita:"
# name unique for this sync (es:"bysincA-B") or "auto" for generated name
name_unico="auto"
# livello di status
statuslevel="0"             ;# 0- progress/status/warning/error
                             # 1- status/warning/error
                             # 2- warning/error
                             # 3- only error
# format of bytes ("readable" or "bytes")
formatnumber="readable"     
# Delete temp files ("yes"/"no") for debug
erasetemp="yes"            
#######################################################################################################################

Gsync 
echo "error code:$?"




