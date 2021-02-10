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
source "gsync.sh"
# two dir for bisync
directory_A="local:/home/aldo/Scrivania/sync test - 2/CasaZita"
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
erasetemp="no"            
#######################################################################################################################

Gsync 
echo "error code:$?"




