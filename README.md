[![](this_web/img/banner800x212.png)](https://beautifuljekyll.com/plans/)

# Gsync
Implementazione di **sync bi-direzionale** tra cartelle basato su **rclone**. Consente il **sync bi-direzionale** tra ```directory locali-google drive-ftp-dropbox``` e molti [altri](https://rclone.org/overview/). Il log delle operazioni, i file cancellati o sovrascritti, un mirror degli elenchi files, vengono salvati su cartelle di recupero in modo da rendere tutte le operazioni reversibili.


## Table of contents

- [Quick start](#quick-start)
- [Status](#status)
- [Problemi con lo script](#problemi-con-lo-script)
- [Documentazione](#documentation)
- [Ringraziamenti](#thanks)
- [Copyright and license](#copyright-and-license)

## Quick start

1. Scarica lo script (tre modalità):

    - [Scaricare solo l'ultima release dello script](https://github.com/sepoina/Gsync/raw/main/bin/gsync.sh)
    - [Scaricare l'intero pacchetto in formato zip](https://github.com/sepoina/Gsync.git)
    - Clonare questo repository: `git clone https://github.com/sepoina/Gsync.git`

1. Installare rclone 
    - [Releases di rclone](https://rclone.org/downloads/)
    - Attenzione! [testato con questa release](https://beta.rclone.org/branch/fix-rmdirs-filter/v1.55.0-beta.5165.358c0832c.fix-rmdirs-filter/)

## Status
[![Size dello script](https://img.badgesize.io/sepoina/Gsync/main/bin/gsync.sh?label=Size%20dello%20script&color=yellow)](https://raw.githubusercontent.com/sepoina/Gsync/main/bin/gsync.sh)


## Problemi con lo script
Puoi segnalare problemi allo script o suggerire miglioramenti [indicandoli qui](https://github.com/sepoina/Gsync/issues/new)

# Documentazione

## Esempio operativo

Sincronizzazione tra una cartella locale e una cartella remota su google drive, livello di status dettagliato, non cancellazione delle directory temporanee create dal processo (a scopo di debug)

## Lo script
```bash
#####################################################################
source "gsync.sh"
# two dir for bisync es: local/remote
directory_A="local:/home/aldo/Scrivania/sync test - 2/CasaZita"
directory_B="googlezita:"
# name unique for this sync (es:"bysincA-B") or "auto" for autoUUID
name_unico="auto"
# livello di status
statuslevel="0"   ;# 0- show progress/status/warning/error
                   # 1- show status/warning/error
                   # 2- show warning/error
                   # 3- show only error
# format of bytes ("readable" or "bytes")
formatnumber="readable"     
# Delete temp files ("yes"/"no") for debug
erasetemp="no"            
#####################################################################
```