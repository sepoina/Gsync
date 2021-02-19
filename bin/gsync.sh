##################################################
#
# Utility
#
##################################################
#
# test var ($1) if undef or "" 
# echo error ($2) and quit proc
function TestVar {
  if [ "$1" == "" ] ; then
   echo "Variabile mancante, $2"
   quitcode=1
  fi
}
#
# Stampa da un tempo in secondi un tempo in formato umanizzato 
# es: 1230 -> 2 ore 23 minuti
#
function PrintTempoUmanizzato {
    local out=""
    local secondi=$1
    local anni=$[ $secondi / 31558150] # anno siderale
    local secondi=$[ $secondi - ($anni * 31558150) ] # togli i secondi siderali degli anni contati
    local giorni=$[($secondi/ 86400) % 365]
    local ore=$[( $secondi/3600) % 24]
    local minuti=$[($secondi / 60) % 60]
    local secondi=$[$secondi % 60]
    local aa=$anni" "$([[ ! $anni -eq  1 ]] && echo "anni" || echo "anno")
    local gg=$giorni" "$([[ ! $giorni -eq  1 ]] && echo "giorni" || echo "giorno")
    local oo=$ore" "$([[ ! $ore -eq  1 ]] && echo "ore" || echo "ora")
    local mm=$minuti" "$([[ ! $minuti -eq  1 ]] && echo "minuti" || echo "minuto")
    local ss=$secondi" "$([[ ! $secondi -eq  1 ]] && echo "secondi" || echo "secondo")
    out="$ss"
    [[ $minuti >  0 ]] && out="$mm e $ss"
    [[ $ore >  0 ]] && out="$oo e $mm"
    [[ $giorni >  0 ]] && out="$gg e $oo"
    [[ $anni >  0 ]] && out="$aa e $gg"
    [[ $anni >  20 ]] && out="Non Calcolabile..." 
    echo -e $out
}
#
#
# Converts bytes value to human-readable string [$1: bytes value]
# https://unix.stackexchange.com/questions/44040/a-standard-tool-to-convert-a-byte-count-into-human-kib-mib-etc-like-du-ls1
#
function bytesToHumanReadable() {
    local i=${1:-0} d="" s=0 S=("Bytes" "Kb" "Mb" "Gb" "Tb" "Pb" "Eb" "Yb" "Zb")
    while ((i > 1024 && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % 1024 * 100 / 1024))
        i=$((i / 1024))
        s=$((s + 1))
    done
    echo "$i$d ${S[$s]}"
}
#
#
# $1 = testo log
# $2 = nomefile tabella formato ogni linea: varie*bytes*varie...
# $3 = bytes/readable
function getBytesFromFile () {
    local bytes=0
    if [ -s "$2" ]; then
        while IFS="" read -r p || [ -n "$p" ]
        do
            [[ $p =~ [^\*]*[\*]+([0123456789]*) ]]  ; # estrae il numero di bytes da questa lista
            [[ BASH_REMATCH[1] -gt 0 ]] && bytes=$(( bytes + ${BASH_REMATCH[1]} ))
        done <  "$2"
        [[ "$3" == "bytes" ]] && echo "$1 $bytes\n"
        [[ "$3" == "readable" ]] && echo "$1 $(bytesToHumanReadable $bytes)\n"
    fi
}
#
# $1 = livello di echo per questo comando
# $2 = tipo di log (text,file)
# $3 = stringa da loggare
function secho() {
    # 0- progress/status/warning/error
    # 1- status/warning/error
    # 2- warning/error
    # 3- error
    local level=$1
    # esci se inferiore al livello da mostrare
    [[ $level < $statuslevel ]] && return
    # text 
    # file
    local type=$2
    if [[ $type == "text" ]] ; then
     printf "$3"
     printf "$3" >> "$logfile"
    fi
}
#
# $1 = separatore iniziale (start) o finale (end)
function logseparator() {
    # start
    # end
    local type=$1
    local timedisi="$(date +"%T // %A %u %B %Y")"
    [[ $type == "start" ]] && local var="------------------------------------------------------------------------ start: $timedisi"; 
    [[ $type == "end" ]]   && local var="-------------------------------------------------------------------------- end: $timedisi"; 
    echo -e "\n ${var:${#var}-90:90} ----" >> "$logfile"
}





function Gsync () {

quitcode=0
TestVar "$directory_A" "'directory_A' deve contenere la cartella di 'origine' di rclone (es \"googledisk:\" oppure \"/home/pippo\")"
TestVar "$directory_B" "'directory_B' deve contenere la cartella di 'destinazione' di rclone (es \"googledisk:\" oppure \"/home/pippo\")"
TestVar "$name_unico" "'name_unico' deve contenere un nome univoco di sincronizzazione della coppia origine e destinazione o 'auto' per generare un id unico"
TestVar "$statuslevel" "'statuslevel' deve contenere un numero (0-all message,1-progress,2-only warn,3-only error)"
TestVar "$formatnumber" "'formatnumber' deve contenere 'readable' o 'bytes'"
TestVar "$erasetemp" "'erasetemp' deve contenere 'yes' o 'no'"
if [[ "$quitcode" == "1" ]] ; then
 return 1
fi

##################################################
#
# GLOBAL VAR
#
##################################################
# strip local: se presente
dir_A=${directory_A#local:}
dir_B=${directory_B#local:}
# se name_unico="auto" genera una unica dir da questa accoppiata (calcola un md5 della stessa)
[[ "$name_unico" == "auto" ]] && name_unico="$(md5sum <<< "$dir_A$dir_B" | head -c 16)"
dir_unica=".gsync/$name_unico"
# dir dei cancellati
dir_erased_A="$dir_A/$dir_unica/delete-or-overwrite/$(date +'%Y.%m.%d.%H-%M-%S')"
dir_erased_B="$dir_B/$dir_unica/delete-or-overwrite/$(date +'%Y.%m.%d.%H-%M-%S')"
# questa dir
dir_proc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# dir locale temporanea
dir_temp="$dir_proc/temp_$name_unico"
logfile="$dir_temp/log/log-$(date +'%Y.%m.%d.%H-%M-%S').txt"
lockfile="$dir_temp/lock"
if [ -f "$lockfile" ]; then
    echo "Operazione precedente non conclusa, esco. Dettagli su \"$dir_temp\""
    return 0
fi








##################################################
#
# Start Proc
#
##################################################
#
# fa pulizia dei precedenti temporanei se presenti [#.1.1]
rm -f -r "$dir_temp"
mkdir "$dir_temp"
mkdir "$dir_temp/lastsync_from_b"
mkdir "$dir_temp/lastsync_from_a"
mkdir "$dir_temp/log"
echo "lock $(date +'%Y.%m.%d.%H-%M-%S')" > "$lockfile" 

# tenta di recuperare l'ultimo update da remoto e lo mette in temp [#.1.2]
secho 0 "text" "Gsync 2.0 - 2021\n"
secho 1 "text" "Operazione delle $(date +"%T // %A %u %B %Y")\n"
secho 1 "text" "Recupero da remoto liste ultimo update..."
rclone copy -v --include "*.txt" --max-depth 1 "$dir_A/$dir_unica" "$dir_temp/lastsync_from_a" 2> /dev/null 
rclone copy -v --include "*.txt" --max-depth 1 "$dir_B/$dir_unica" "$dir_temp/lastsync_from_b" 2> /dev/null

# verifica se c'è il file lastsync.txt 
  if [ ! -f "$dir_temp/lastsync_from_b/lastsync.txt" ]; then
    tempopassato=-1
    stext="Ultimo update non trovato, alcune operazioni possono essere imprecise..:\nfile non trovato: \"$dir_B/$dir_unica/lastsync_from_b/lastsync.txt\"\n"
  else 
    tempopassato="$(expr $(date +%s) - $(cat "$dir_temp/lastsync_from_b/lastsync.txt" | date +%s -f -))"
    stext="Ultimo aggiornamento completo: $(PrintTempoUmanizzato "$tempopassato") fa\n"
  fi

#confronta le due versioni per sapere se ci sono disallineamenti [#.1.3] 
  diff -a --unchanged-line-format="" --old-line-format="Solo in A:%L" --new-line-format="Solo in B:%L" "$dir_temp/lastsync_from_b/allfiles.txt" "$dir_temp/lastsync_from_a/allfiles.txt" | sed '/^[^\*]*\*-1\*.*$/d' > "$dir_temp/error_non_allineati.txt"
  status_sync="$(wc -l "$dir_temp/error_non_allineati.txt" | awk '{ print $1 }')"
  if [ $status_sync -eq 0 ] ; then
      secho 1 "text" "(ok)\n$stext"
    else 
      secho 3 "text" "(warning)\n\nWarning errore di sincronismo, le copie non sono allineate\n\ndettagli su \"$dir_temp/error_non_allineati.txt\"\n$stext"
  fi



##################################################
#
# Lavori sulle liste FILES
#
##################################################

# ottiene una lista dei files e delle cartelle da entrambi i percorsi escludendo la cartella .gsync [#.2.1]
    secho 0 "text" "Tolgo directory // "
    rclone lsf -R  --separator "*" --format "tsp" "$dir_A" --exclude "/.gsync/**" | sort > "$dir_temp/A_tot.txt"
    rclone lsf -R  --separator "*" --format "tsp" "$dir_B" --exclude "/.gsync/**" | sort > "$dir_temp/B_tot.txt"



# toglie dalle relative liste gli immutati e le directory [#.2.2] 
    secho 0 "text" "Tolgo immutati // "
    diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/A_tot.txt" "$dir_temp/B_tot.txt" | sed '/^[^\*]*\*-1\*.*$/d' > "$dir_temp/A_file_new.txt"
    diff -a --unchanged-line-format="" --old-line-format="" --new-line-format="%L" "$dir_temp/A_tot.txt" "$dir_temp/B_tot.txt" | sed '/^[^\*]*\*-1\*.*$/d' > "$dir_temp/B_file_new.txt"


# se il file è presente in entrambe le destinazioni fai prevalere la più recente [#.2.3]
    secho 0 "text" "Tolgo obsoleti per data // "
    while IFS="" read -r p || [ -n "$p" ] 
    do 
      A_file=$(echo $p | cut -f 3- -d "*") ; # elimina ciò che non è nome file
      B_found=$(fgrep "*$A_file" "$dir_temp/B_file_new.txt") ; # vede se c'è nel file di B
      if [[ -n $B_found ]]; then
            data_A=$(echo $p | cut -f 1 -d "*")              ; # data file originale
            data_B=$(echo $B_found | cut -f 1 -d "*")     ; # data file destinazione
            if [[ "$data_A" > "$data_B" ]] ; then 
              echo $B_found >> "$dir_temp/B_file_obsolete.txt"
              else
              echo $p >> "$dir_temp/A_file_obsolete.txt"
            fi
      fi
    done <  "$dir_temp/A_file_new.txt"




# calcola se ci sono file rimossi [#.2.4]
    # se presente ultimo backup della lista di A in B 
    if [ -f "$dir_temp/lastsync_from_b/allfiles.txt" ]; then
      secho 0 "text" "Tolgo obsoleti per cancellazione // "
      # se esiste una sincronizzazione precedente togli i file che appaiono "nuovi" ma invece esistevano già, vuol dire che li ha cancellati nell'altro mirror
      diff -a --unchanged-line-format="%L" --old-line-format="" --new-line-format="" "$dir_temp/A_file_new.txt" "$dir_temp/lastsync_from_b/allfiles.txt" > "$dir_temp/B_file_erased.txt"
      diff -a --unchanged-line-format="%L" --old-line-format="" --new-line-format="" "$dir_temp/B_file_new.txt" "$dir_temp/lastsync_from_a/allfiles.txt" > "$dir_temp/A_file_erased.txt"
      cat "$dir_temp/A_file_erased.txt" >> "$dir_temp/B_file_obsolete.txt"
      cat "$dir_temp/B_file_erased.txt" >> "$dir_temp/A_file_obsolete.txt"
    fi


    
    
# rimuove i file obsoleti dagli elenchi degli "apparenti nuovi" [#.2.5]
    # E in caso li rimuove dalla lista di appartenenza
    if [ -f "$dir_temp/A_file_obsolete.txt" ]; then
      sort -o "$dir_temp/A_file_obsolete.txt" "$dir_temp/A_file_obsolete.txt"    ; # li riordina se necessario
      cp "$dir_temp/A_file_new.txt" "$dir_temp/A_file_new_pre_remove_obsolete.txt"
      diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/A_file_new_pre_remove_obsolete.txt" "$dir_temp/A_file_obsolete.txt" > "$dir_temp/A_file_new.txt"
    fi 
    if [ -f "$dir_temp/B_file_obsolete.txt" ]; then
      sort -o "$dir_temp/B_file_obsolete.txt" "$dir_temp/B_file_obsolete.txt"    ; # li riordina se necessario
      cp "$dir_temp/B_file_new.txt" "$dir_temp/B_file_new_pre_remove_obsolete.txt"
      diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/B_file_new_pre_remove_obsolete.txt" "$dir_temp/B_file_obsolete.txt" > "$dir_temp/B_file_new.txt"
    fi 



# Pulisce i file togliendo la data e la dimensione [#.2.6]
    secho 0 "text" "Tolgo dati inutili.\n"
    [[ -s "$dir_temp/A_file_new.txt" ]] &&  cat "$dir_temp/A_file_new.txt" | sed -e 's/^[^\*]*\*[^\*]*\*//' | tee "$dir_temp/A_file_new_final.txt" > /dev/null
    [[ -s "$dir_temp/B_file_new.txt" ]] &&  cat "$dir_temp/B_file_new.txt" | sed -e 's/^[^\*]*\*[^\*]*\*//' | tee "$dir_temp/B_file_new_final.txt" > /dev/null



##################################################
#
# Lavori sulle liste DIRECTORY
#
##################################################


# Calcola le directory vuote da aggiungere/cancellare. Quelle con files vengono già aggiunte di suo. [#.2.7]
    # Tutte le cartelle (elimina i file, elimina la data, ordina)
    cat "$dir_temp/A_tot.txt" | sed '/^[^\*]*\*-1\*.*$/!d' | sed -e 's/^[^\*]*\*[^\*]*\*//' | sort > "$dir_temp/A_dir.txt"
    cat "$dir_temp/B_tot.txt" | sed '/^[^\*]*\*-1\*.*$/!d' | sed -e 's/^[^\*]*\*[^\*]*\*//' | sort > "$dir_temp/B_dir.txt"
    # Rimuove duplicati
    diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/A_dir.txt" "$dir_temp/B_dir.txt" > "$dir_temp/A_dir_new_empty.txt"
    diff -a --unchanged-line-format="" --old-line-format="" --new-line-format="%L" "$dir_temp/A_dir.txt" "$dir_temp/B_dir.txt" > "$dir_temp/B_dir_new_empty.txt"
    # toglie da questa operazione le cartelle con contenuto (non serve)
    #while IFS="" read -r p || [ -n "$p" ] 
    #do 
    #  riccorenze=$(fgrep "*$p" "$dir_temp/A_tot.txt" | wc -l) ; # conta il numero di ricorrenze solo se 1 è vuota e va considerata
    #  [[ 1 -eq 1 ]] && echo $p >> "$dir_temp/A_dir_new_empty.txt"
    #done <  "$dir_temp/A_dir_new_all.txt"
    #while IFS="" read -r p || [ -n "$p" ] 
    #do 
    #  riccorenze=$(fgrep "*$p" "$dir_temp/B_tot.txt" | wc -l) ; # conta il numero di ricorrenze solo se 1 è vuota e va considerata
    #  [[ 1 -eq 1 ]] && echo $p >> "$dir_temp/B_dir_new_empty.txt"
    #done <  "$dir_temp/B_dir_new_all.txt"
    # Se directory già presente in backup precedente è un orfana [#.2.8]
    if [ -f "$dir_temp/lastsync_from_b/alldirs.txt" ]; then
      diff -a --unchanged-line-format="%L" --old-line-format="" --new-line-format="" "$dir_temp/A_dir_new_empty.txt" "$dir_temp/lastsync_from_b/alldirs.txt" | sed -e 's/$/**/' > "$dir_temp/A_dir_obsolete.txt"
      diff -a --unchanged-line-format="%L" --old-line-format="" --new-line-format="" "$dir_temp/B_dir_new_empty.txt" "$dir_temp/lastsync_from_a/alldirs.txt" | sed -e 's/$/**/' > "$dir_temp/B_dir_obsolete.txt"    
      # le nuove new non erano presenti in quegli elenchi, metti solo le nuove
      diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/A_dir_new_empty.txt" "$dir_temp/lastsync_from_b/alldirs.txt" | sed -e 's/$/**/' > "$dir_temp/A_dir_new_empty_purge.txt"
      diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/B_dir_new_empty.txt" "$dir_temp/lastsync_from_a/alldirs.txt" | sed -e 's/$/**/' > "$dir_temp/B_dir_new_empty_purge.txt"          
    fi
    # Se ne ha trovate le rimuove dalle liste di appartenenza
    # if [ -f "$dir_temp/A_dir_obsolete.txt" ]; then
    #  sort -o "$dir_temp/A_dir_obsolete.txt" "$dir_temp/A_dir_obsolete.txt"    ; # li riordina se necessario
    #  cp "$dir_temp/A_dir_new_empty.txt" "$dir_temp/A_dir_new_pre_remove_obsolete.txt"
    #  diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/A_dir_new_pre_remove_obsolete.txt" "$dir_temp/A_dir_obsolete.txt" > "$dir_temp/A_dir_new_empty.txt"
    #fi 
    #if [ -f "$dir_temp/B_dir_obsolete.txt" ]; then
    #  sort -o "$dir_temp/B_dir_obsolete.txt" "$dir_temp/B_dir_obsolete.txt"    ; # li riordina se necessario
    #  cp "$dir_temp/B_dir_new_empty.txt" "$dir_temp/B_dir_new_pre_remove_obsolete.txt"
    #  diff -a --unchanged-line-format="" --old-line-format="%L" --new-line-format="" "$dir_temp/B_dir_new_pre_remove_obsolete.txt" "$dir_temp/B_dir_obsolete.txt" > "$dir_temp/B_dir_new_empty.txt"
    #fi 


##################################################
#
# Sincronizzazione FILES
#
##################################################

# backup obsolete A [#.3.1]
if [ -s "$dir_temp/A_file_obsolete.txt" ]; then
 secho 1 "text" "Backup file di A obsoleti "
 logseparator "start"
 #creo copia pulita degli obsoleti di A in erased di A
 cat "$dir_temp/A_file_obsolete.txt" | sed -e 's/^[^\*]*\*[^\*]*\*//' | tee "$dir_temp/A_file_obsolete_final.txt" > /dev/null
 rclone copy --files-from "$dir_temp/A_file_obsolete_final.txt" --check-first -v --log-file "$logfile" "$dir_A" "$dir_erased_A"  
 rclone delete --files-from "$dir_temp/A_file_obsolete_final.txt" --check-first -v --log-file "$logfile" "$dir_A" 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# backup obsolete B  [#.3.2]
if [ -s "$dir_temp/B_file_obsolete.txt" ]; then
 secho 1 "text" "Backup file di B obsoleti "
 logseparator "start"
 #creo copia pulita degli obsoleti di B in erased di B
 cat "$dir_temp/B_file_obsolete.txt" | sed -e 's/^[^\*]*\*[^\*]*\*//' | tee "$dir_temp/B_file_obsolete_final.txt" > /dev/null
 rclone copy --files-from "$dir_temp/B_file_obsolete_final.txt" --check-first -v --log-file "$logfile" "$dir_B" "$dir_erased_B"  
 rclone delete --files-from "$dir_temp/B_file_obsolete_final.txt" --check-first -v --log-file "$logfile" "$dir_B" 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# sincronizzazione A -> B [#.3.3]
if [ -s "$dir_temp/A_file_new_final.txt" ]; then
 secho 1 "text" "Copio nuovi files A -> B  "
 logseparator "start"
 rclone copy --files-from "$dir_temp/A_file_new_final.txt" --check-first -v --log-file "$logfile" "$dir_A" "$dir_B" ; 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# sincronizzazione A <- B [#.3.4]
if [ -s "$dir_temp/B_file_new_final.txt" ]; then
 secho 1 "text" "Copio nuovi files A <- B  " 
 logseparator "start"
 rclone copy --files-from "$dir_temp/B_file_new_final.txt" --check-first -v --log-file "$logfile" "$dir_B" "$dir_A" ; 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi


##################################################
#
# Sincronizzazione CARTELLE
#
##################################################

#secho 1 "text" "Operazioni su cartelle  "
# Creazione directory nuove e vuote in A [#.3.5]
if [ -s "$dir_temp/B_dir_new_empty_purge.txt" ]; then
 secho 1 "text" "Creo cartelle nuove in A " 
 logseparator "start"
 cat "$dir_temp/B_dir_new_empty_purge.txt" >> "$logfile" 
 rclone copy --include-from "$dir_temp/B_dir_new_empty_purge.txt" --min-size 5000G --min-age 100y --create-empty-src-dirs --check-first -v --log-file "$logfile" "$dir_B" "$dir_A" ; 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# Creazione directory nuove e vuote in B [#.3.6]
if [ -s "$dir_temp/A_dir_new_empty_purge.txt" ]; then
 secho 1 "text" "Creo cartelle nuove in B " 
 logseparator "start"
 cat "$dir_temp/A_dir_new_empty_purge.txt" >> "$logfile" 
 rclone copy --include-from "$dir_temp/A_dir_new_empty_purge.txt" --min-size 5000G --min-age 100y --create-empty-src-dirs --check-first -v --log-file "$logfile" "$dir_A" "$dir_B" ; 
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# Eliminazione directory obsolete e vuote in A [#.3.7]
if [ -s "$dir_temp/A_dir_obsolete.txt" ]; then
 secho 1 "text" "Elimino dir obsolete in A " 
 logseparator "start"
 rclone delete --include-from "$dir_temp/A_dir_obsolete.txt" --rmdirs --check-first -v --log-file "$logfile" "$dir_A"
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi

# Eliminazione directory obsolete e vuote in B [#.3.8]
if [ -s "$dir_temp/B_dir_obsolete.txt" ]; then
 secho 1 "text" "Elimino dir obsolete in B " 
 logseparator "start"
 rclone delete --include-from "$dir_temp/B_dir_obsolete.txt" --rmdirs --check-first -v --log-file "$logfile" "$dir_B"
 secho 1 "text" "(ok)\n"
 logseparator "end"
fi
# secho 1 "text" "(ok)\n"
# read -p "Press enter to continue"

Status="$(echo "\
$(getBytesFromFile "   A --> B  |" "$dir_temp/A_file_new.txt"     "$formatnumber")\
$(getBytesFromFile "   A <-- B  |" "$dir_temp/B_file_new.txt"     "$formatnumber")\
$(getBytesFromFile "   A > bak  |" "$dir_temp/B_file_erased.txt"  "$formatnumber")\
$(getBytesFromFile "   B > bak  |" "$dir_temp/A_file_erased.txt"  "$formatnumber")")\
"


##################################################
#
# Test
#
##################################################

# verifica scaricando le nuove liste da A e B e comparandole per verificare l'assenza di desincro [#.4.1] [#.4.2]
    secho 1 "text" "Verifico A == B...."
    rclone lsf -R  --separator "*" --format "tsp" "$dir_A" --exclude "/.gsync/**" | sort > "$dir_temp/A_tot_post_update.txt"
    rclone lsf -R  --separator "*" --format "tsp" "$dir_B" --exclude "/.gsync/**" | sort > "$dir_temp/B_tot_post_update.txt"
    diff -a --unchanged-line-format="" --old-line-format="Solo in A:%L" --new-line-format="Solo in B:%L" "$dir_temp/A_tot_post_update.txt" "$dir_temp/B_tot_post_update.txt" | sed '/^[^\*]*\*-1\*.*$/d' > "$dir_temp/error_post_update.txt"
    status_sync="$(wc -l "$dir_temp/error_post_update.txt" | awk '{ print $1 }')"
    if [ $status_sync -eq 0 ] ; then
       secho 1 "text" "(ok)\n"
      else 
       secho 3 "text" "\nErrore di sincronismo, alcuni file non sincronizzati, riprovare"
       secho 3 "text" "\ndettagli su \"$dir_temp/Error_post_update.txt\""
       rm -f "$lockfile" 
       return 1
    fi
    # estrae corretta struttura directory
    cat "$dir_temp/A_tot_post_update.txt" | sed '/^[^\*]*\*-1\*.*$/!d' | sed -e 's/^[^\*]*\*[^\*]*\*//' | sort > "$dir_temp/alldirs.txt"



##################################################
#
# Update info A // B
#
##################################################

# updata copiando lista di files e creando lastsync.txt [#.4.3] [#.4.4]
secho 1 "text" "New List "
cp "$dir_temp/A_tot_post_update.txt" "$dir_temp/allfiles.txt"
date +"%Y-%m-%d %H:%M:%S" > "$dir_temp/lastsync.txt"
echo -e -n "/lastsync.txt\n/alldirs.txt\n/allfiles.txt\nlog/**" > "$dir_temp/filetoremote.txt"
rclone copy --include-from "$dir_temp/filetoremote.txt" --check-first -q "$dir_temp" "$dir_A/$dir_unica" 
secho 1 "text" "A "
rclone copy --include-from "$dir_temp/filetoremote.txt" --check-first -q "$dir_temp" "$dir_B/$dir_unica" 
secho 1 "text" "// B"
rm -f "$dir_temp/filetoremote.txt"
# elimina da temp i file 0 size
find "$dir_temp" -type f -size 0 -delete
secho 1 "text" "....(ok) \n"
if [ "$Status" != "" ] ; then
  secho 2 "text" "$Status"
 else
  secho 2 "text" "No bytes transfered.\n"
fi
# sblocca la procedura
rm -f "$lockfile" 
# cancella temp se così richiesto [#.4.5]
[ "$erasetemp" == "yes" ] && rm -f -r "$dir_temp"
return 0
}