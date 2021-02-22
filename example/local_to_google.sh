#!/bin/bash
#######################################################################################################################
# gsync 2.0 febbraio 2021
# rclone version from
# https://beta.rclone.org/branch/fix-rmdirs-filter/v1.55.0-beta.5165.358c0832c.fix-rmdirs-filter/
#
# Gsync << json-gsync
#     {    
#                    "A"  : source dir 'local:/mnt/zita' 
#                    "B"  : destin_dir 'googledisk:zita_mirror'
#                 "name"  : "zita-and-remote" or "auto" for auto generated uuid
#          "statuslevel"  : "0" (0-all message,1-progress,2-only warn,3-only error)
#           "fullreport"  : "y" for detailed report of 0 values
#         "formatnumber"  : "readable" output es:4.51Mb or "bytes" for numeric format
#            "erasetemp"  : "y" for erase temp dir after sync
#     }   
# json-gsync
# [[ $? -gt 0 ]] && echo "error code:$?"
#
#######################################################################################################################
source "gsync.sh"

Gsync << json-gsync
    {    
                   "A" : "local:/mnt/Laboratorio/L/Backup/googlezita",  
                   "B" : "googlezita:",
                "name" : "auto",
         "statuslevel" : "2",
          "fullreport" : "n",
        "formatnumber" : "readable",
           "erasetemp" : "y"
    }   
json-gsync
[[ $? -gt 0 ]] && echo "error code:$?"




