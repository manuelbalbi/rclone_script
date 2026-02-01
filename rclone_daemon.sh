#!/bin/bash
source "$(dirname "$0")/vars.sh"

# 1. Definisci cosa escludere dal monitoraggio per evitare loop infiniti
# Escludi log, cache e file temporanei comuni
EXCLUDE_REG="(.*\.rclone.*|.*\.cache.*|.*\.config/rclone.*|.*$LOGFILE.*)"

echo "Watcher avviato su $HOME..."

# 2. Avvia il monitoraggio
fsnotifywait --fanotify -m -r -e modify,create,delete,move --exclude "$EXCLUDE_REG" "$HOME" | while read -r directory events filename; do

    # Se un sync è già in corso, saltiamo l'evento (inutile accumulare)
    if pgrep -x "rclone" > /dev/null; then
        continue
    fi

    # Attendi che l'attività dell'utente si calmi (Debounce)
    # Questo ciclo "svuota" gli eventi ravvicinati
    sleep 20

    echo "$(date): Avvio sync per modifica su $filename" >> "$LOGFILE"

    # Esegui i sync in sequenza
    # --fast-list riduce il numero di richieste API (molto utile per Google Drive)
    rclone sync "$HOME/" OneDrive:/Bazzite/ --update --metadata --fast-list --log-level "$LOGLVL" >> "$LOGFILE" 2>&1
    rclone sync "$HOME/" Google:/ --update --metadata --fast-list --log-level "$LOGLVL" >> "$LOGFILE" 2>&1
done
