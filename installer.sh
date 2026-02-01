#!/bin/bash

# Importing script global variables
source "$(dirname "$0")/vars.sh"

# Create config and install directory
mkdir -p "$INSTALLDIR"

# Delete logs older than $TFINDFLUSH
find "$INSTALLDIR" -type f -name "*log*" -mtime +"$TFINDFLUSH" -delete

# --- UPDATE LOGIC ---
echo "Controllo versione in corso da ${UPDATE_URL}..."
printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Verifica versione script da ${UPDATE_URL}..." >> "$LOGFILE"

# Recupera la versione e puliscila da ogni carattere che non sia un numero
REMOTE_BUILD=$(curl -fsL "$UPDATE_URL" | grep "^BUILD=" | head -1 | tr -d -c '0-9')

# Controllo se REMOTE_BUILD è vuoto o non numerico
if [[ -z "$REMOTE_BUILD" ]] || ! [[ "$REMOTE_BUILD" =~ ^[0-9]+$ ]]; then
    ACTION="error"
else
    # Confronto numerico (Bash friendly)
    if (( REMOTE_BUILD > BUILD )); then
        ACTION="update"
    elif (( REMOTE_BUILD < BUILD )); then
        ACTION="dev_mode"
    else
        ACTION="skip"
    fi
fi

case "$ACTION" in
    "update")
        echo "Versione $REMOTE_BUILD disponibile. Aggiornamento in corso..."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Aggiorno alla build $REMOTE_BUILD" >> "$LOGFILE"

        # Scarica in file temp e sostituisce solo se il download ha successo
        if curl -fsL "$UPDATE_URL" -o "${SCRIPT_PATH}.tmp"; then
            mv "${SCRIPT_PATH}.tmp" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo "Aggiornamento completato. Riavvio..."
            exec "$SCRIPT_PATH" "$@"
        else
            echo "Errore durante il download dell'aggiornamento."
            exit 1
        fi
        ;;
    "dev_mode")
        echo "Modalità Dev: v${BUILD} locale > v${REMOTE_BUILD} remota."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Versione locale superiore alla remota" >> "$LOGFILE"
        ;;
    "error")
        echo "Errore: Impossibile contattare il server o leggere la build."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERRORE" "Fallito recupero versione remota" >> "$LOGFILE"
        ;;
    *)
        echo "Script aggiornato (Build: ${BUILD})."
        ;;
esac


# -------------------------------------------------------------------------------------------------
# Create missing config files
if [ ! -f "$CONFUP" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_UP"
    cat <<EOF > "$CONFUP"
# rclone_script default configuration created for v. ${VERSIONE} build ${BUILD} file $CONF_FILE_UP
# Please refer to https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for configuring rsync filters

# Exclude hidden paths
- .*{/**,}

# Including
+ .config/rclone_script/**
+ Documenti/**
+ Games/**
+ Immagini/**
+ Musica/**
+ Pubblici/**
+ Scrivania/**
+ Video/**

# Exclude everything else
- *
EOF
fi

if [ ! -f "$CONFDW" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_DOWN"
    cat <<EOF > "$CONFDW"
# rclone_script default configuration created for v. ${VERSIONE} build ${BUILD} file $CONF_FILE_UP
# Please refer to https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for configuring rsync filters

# Exclude hidden paths
- .*{/**,}

# Including
+ .config/rclone_script/**
+ Documenti/**
+ Games/**
+ Immagini/**
+ Musica/**
+ Pubblici/**
+ Scrivania/**
+ Video/**

# Exclude everything else
- *
EOF
fi

# Controllo presenza dipendenze
REQUISITI=(
"rclone"
"rsync"
)

for bin in "${REQUISITI[@]}"; do
    if ! command -v "$bin" &> /dev/null; then
        echo -e "Script interrotto, non è installato il comando $bin."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERRORE" "MANCA requisito $bin" >> "$LOGFILE"
        exit 1
    fi
done
