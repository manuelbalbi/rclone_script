#!/bin/bash

# -------------------------------------------------------------------------------------------------
# --------------- SCRIPT DI SINCRONIZZAZIONE CON I SERVIZI CLOUD UTILIZZANDO rclone ---------------
# ---------------- ATTIVAZIONE DI BACKUP E COPIA DI FILE SELEZIONATI CON rsync / cp ---------------
# -------------------------------------------------------------------------------------------------

# Dichiarazione versione script per confronto aggiornamento su GitHub in formato AAAAMMGG e per stampa su file e log
<<<<<<< Updated upstream
VERSIONE="2.5"
BUILD=20260205
=======
VERSIONE="2.5.1"
BUILD=20260205251
>>>>>>> Stashed changes

# Configurazione per repository GitHub pubblico
REPO_OWNER="manuelbalbi"
REPO_NAME="rclone_script"
BRANCH="main"
GITFILE="rclone_script.sh"
GITPACKAGE=("var.sh" "rclone_script.sh")
UPDATE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/refs/heads/main/${GITFILE}" # https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh
SCRIPT_PATH="$(readlink -f "$0")"

# Configurazione percorsi, file di log, file di configurazione e tempi di vita dei documenti di sincronizzazione e di pulizia backlog
INSTALLDIR="$HOME/.config/rclone_script"
TEMP_FILE="temp.zip"
TEMP_EXTRACT="$INSTALLDIR/tmp"
LOGNAME="$(date +%F)_log_rclone_${BUILD}.log"
LOGFILE="${INSTALLDIR}/${LOGNAME}"
CONF_FILE_UP="rclone_script_upload.conf"
CONF_FILE_DOWN="rclone_script_download.conf"
CONF_DIR="config_files"
CONFUP="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_UP}"
CONFDW="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_DOWN}"
CONFSERVICE="$HOME/.config/systemd/user/rclone-bisync.service"
CONFTIMER="$HOME/.config/systemd/user/rclone-bisync.timer"
VITA="90d" # configurazione vita dei documenti da sincronizzare con bisync
TFINDFLUSH="30" # tempo in giorni per -mtime su comando find per cancellazione file di log / pulizia backlog vecchio
LOCKFILEDIR="$HOME/.cache/rclone/bisync/" # riferimento a https://rclone.org/bisync/#lock-file
RCLONE_REMOTE=$(rclone listremotes | head -n 1 | tr -d ':') # primo servizio configurato su rclone

# Livello di informazioni registrate da rclone nel file di log
# Seleziona il livello attivando/disattivando il commento
LOGLVL="INFO"
#LOGLVL="DEBUG"
# Configurazioni base dello script
DR="Attivare dry-run"
DRYRUN="--dry-run"
TSYNC=""

# Definizione valori colori
GREEN="\e[38;2;97;187;70m"
YELLOW="\e[38;2;245;211;0m"
ORANGE="\e[38;2;247;148;29m"
RED="\e[38;2;226;31;38m"
PURPLE="\e[38;2;151;57;153m"
BLUE="\e[38;2;0;156;222m"
# Formattazione testo
BOLD="\e[1m"
ITALIC="\e[3m"
RESET_BOLD="\e[22m"
RESET_ITALIC="\e[23m"
# Reset formattazione
RESET="\e[0m"

# Configurazione estetica per gum/ugum mediante variabili d'ambiente
export GUM_CHOOSE_CURSOR=" "
export GUM_CHOOSE_CURSOR_FOREGROUND="#FF9F1C"
export GUM_CHOOSE_SELECTED_FOREGROUND="#FF9F1C"

# Configurazione spinner
six_dot_cell_pattern=("⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇")
eight_dot_cell_pattern=("⣾" "⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽")

# Set the pattern
braille_spinner=("${eight_dot_cell_pattern[@]}")

# Set the duration for each spinner frame (in seconds)
frame_duration=0.1

# -------------------------------------------------------------------------------------------------
# ------------------------------------------ AVVIO SCRIPT -----------------------------------------

printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "--- AVVIO rclone_script v. ${VERSIONE} build ${BUILD} -------------------------------------------------------------" >> "$LOGFILE"

clear
tput csr 9 $(($(tput lines) - 1))

#   disegna le 9 righe di intestazione fissa (righe 0-8)
tput cup 0 0
echo -e "${GREEN}               ⠘⣿⡇                                               ⠻⠃          ⣼${RESET}"
echo -e "${YELLOW}    ⣿⣤⡿⠛⠃ ⣴⡿⠛⠻⠏ ⣿⡇  ⣶⠿⠛⠿⣶  ⢸⣷⡾⠛⠻⣿⡄  ⣰⡿⠛⠻⣷     ⢀⣾⠛⠛⠿⠃ ⢠⣾⠟⠛⠿ ⢸⣧⣾⠟⠛ ⣿⡇ ⢸⣷⡾⠛⠻⣷  ⠛⣿⠛⠛  ⢠⣾⠟⠛⠻⣷${RESET}"
echo -e "${ORANGE}    ⣿⡏   ⢠⣿     ⣿⡇ ⣼⡏   ⢸⣷ ⢸⣿   ⢸⡇ ⢠⣿⣀⣀⣀⣹⡇    ⠘⣿⣄    ⣿⠁    ⢸⣿    ⣿⡇ ⢸⣿   ⠘⣿  ⣿       ⢀⣼⠏${RESET}"
echo -e "${RED}    ⣿⡇   ⢸⣿     ⣿⡇ ⢿⡇   ⢸⣿ ⢸⣿   ⢸⡇ ⠸⣿⠉⠉⠉⠉⠁      ⠉⠛⣿⡄ ⣿     ⢸⣿    ⣿⡇ ⢸⣿   ⢀⣿  ⣿     ⣠⣾⠟⠁ ${RESET}"
echo -e "${PURPLE}    ⣿⡇    ⢿⣦⣀⣀⣀ ⣿⡇ ⠈⣿⣄⣀⣀⣿⠃ ⢸⣿   ⢸⡇  ⢿⣦⣀⣀⣀⡄    ⢠⣀ ⣀⣼⠇ ⠻⣷⣀⣀⣀ ⢸⣿    ⣿⡇ ⢸⣿⣄⣀⣀⣾⠏  ⣿⣄⢀ ⣠⣾⣿⣁⣀⣀⡄${RESET}"
echo -e "${BLUE}    ⠉⠁     ⠈⠉⠉⠁ ⠉⠁   ⠉⠉⠉   ⠈⠉   ⠈⠁   ⠈⠉⠉⠉      ⠉⠉⠉⠁    ⠉⠉⠉ ⠈⠉    ⠉⠁ ⢸⣿ ⠉⠉⠁    ⠉⠉ ⠻⠿⠿⠿⠿⠿⠃${RESET}"
echo -e "${BLUE}                                                                    ⢸⣿${RESET}"
echo -e "${BLUE}                                                                     ⠉ ${RESET} di Manuel Balbi - ${BOLD}v.${VERSIONE}${RESET_BOLD} build ${ITALIC}${BUILD}${RESET}"
tput cup 9 0

# ---------------------------------------- INIZIO CONTROLLI ---------------------------------------
# Controllo bash
if [ -z "$BASH_VERSION" ]; then
    echo "Questo script richiede Bash."
    exit 1
fi

# Creo la cartella per il log se non già esistente (uso le virgolette per sicurezza)
mkdir -p "$INSTALLDIR"

# Cerco e cancello file di log più vecchi di $TFINDFLUSH
find "$INSTALLDIR" -type f -name "*log*" -mtime +"$TFINDFLUSH" -delete

# --- LOGICA DI AGGIORNAMENTO ---
echo "Controllo versione in corso da ${UPDATE_URL}..."
printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Verifica versione script da ${UPDATE_URL}..." >> "$LOGFILE"

# Recupera la versione e puliscila da ogni carattere che non sia un numero
REMOTE_BUILD=$(curl -sL "$UPDATE_URL" | grep "^BUILD=" | head -1 | tr -d -c '0-9')

# Controllo di sicurezza: se non è un numero, imposta a 0 o esci
if ! [[ "$REMOTE_BUILD" =~ ^[0-9]+$ ]]; then
    echo "Errore: Impossibile leggere la versione remota (ricevuto: $REMOTE_BUILD)"
    printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERRORE" "Impossibile leggere la versione da GitHub, restituito: $REMOTE_BUILD..." >> "$LOGFILE"
    ACTION="error"
else
    # Ora il confronto numerico è sicuro
    if [ "$REMOTE_BUILD" -gt "${BUILD}" ]; then
        ACTION="update"
    elif [ "$REMOTE_BUILD" -lt "${BUILD}" ]; then
        ACTION="dev_mode"
    else
        ACTION="skip"
    fi
fi

case "$ACTION" in
    "update")
        echo "Versione $REMOTE_BUILD disponibile. Aggiornamento in corso..."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Disponibile versione $REMOTE_BUILD, aggiorno..." >> "$LOGFILE"
        curl -sL "$UPDATE_URL" -o "${SCRIPT_PATH}.tmp" && mv "${SCRIPT_PATH}.tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        exec "$SCRIPT_PATH" "$@" # esegue lo script sostituendo il processo in esecuzione con il medesimo PID e uccidendo l'attuale
        ;;
    "dev_mode")
        echo "Stai usando una versione locale (${BUILD}) più recente di GitHub ($REMOTE_BUILD)."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Versione locale (${BUILD}) più recente di GitHub ($REMOTE_BUILD)." >> "$LOGFILE"
        ;;
    "error")
        echo "Errore: Impossibile determinare la versione da GitHub."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Errore nel determinare la versione da GitHub." >> "$LOGFILE"
        ;;
    "skip"|*)
        echo "Script già aggiornato (build ${BUILD})."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Versione locale (${BUILD}), versione GitHub ($REMOTE_BUILD)." >> "$LOGFILE"
        ;;
esac

# -------------------------------------------------------------------------------------------------
# Creazione file di configurazione rclone (Upload)
if [ ! -f "$CONFUP" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_UP"
    cat <<EOF > "$CONFUP"
# Configurazione predefinita per rclone_script definita da v. ${VERSIONE} build ${BUILD} parametro '--filter-from' file $CONF_FILE_UP
# Configura aggiungendo o cancellando righe con riferimento a https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file

# 1. Inclusioni specifiche
+ Documenti/GitHub/**
+ .config/rclone_script

# 2. Esclusione generale dei file/cartelle nascoste
- .*{/**,}

# 3. Altre esclusioni e inclusioni standard
- Documenti/Backup/**
+ Documenti/**
- Games/Heroic/**
+ Games/**
- Immagini/Windows/**
- Immagini/2025-12-22 milena smash cake/**
+ Immagini/**
+ Musica/**
+ Pubblici/**
+ Scrivania/**
- Video/Radeon ReLive/**
+ Video/**

# 4. Escludi tutto il resto
- *
EOF
fi

# Creazione file di configurazione rclone (Download)
if [ ! -f "$CONFDW" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_DOWN"
    cat <<EOF > "$CONFDW"
# Configurazione predefinita per rclone_script definita da v. ${VERSIONE} build ${BUILD} parametro '--filter-from' file $CONF_FILE_DOWN
# Configura aggiungendo o cancellando righe con riferimento a https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file

# 1. Inclusioni specifiche anche nascoste
+ Documenti/GitHub/**
+ .config/rclone_script

# 2. Esclusione generale dei file/cartelle nascoste
- .*{/**,}

# 3. Altre esclusioni e inclusioni standard
- Documenti/Backup/**
+ Documenti/**
- Immagini/Windows/**
+ Immagini/**
+ Musica/**
+ Scrivania/**
- Video/Radeon ReLive/**
+ Video/**

# 4. Escludi tutto il resto
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
        trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Script interrotto, non è installato il comando $bin.'; exit" EXIT
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERRORE" "MANCA requisito $bin" >> "$LOGFILE"
        exit 1
    fi
done

# Controllo esiste almeno un servizio remoto configurato
if [ -z "$RCLONE_REMOTE" ]; then
    echo -e "Errore: Nessun remote configurato in rclone, assicurarsi di configurarne almeno uno con ${BOLD}rclone config${RESET_BOLD}!"
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERRORE" "Non risulta alcun servizio configurato su rclone, assicurarsi di configurarne almeno uno con rclone config." >> "$LOGFILE"
    exit 1
fi

# -------------------------------------------------------------------------------------------------
# Function to start the spinner in the background
start_spinner() {
  (
    spinner_index=0
    while :; do
      printf "\r%s " "${braille_spinner[spinner_index]}"
      spinner_index=$(( (spinner_index + 1) % ${#braille_spinner[@]} ))
      sleep "$frame_duration"
    done
  ) &
  spinner_pid=$!
  disown
}

# Function to stop the spinner with U+2800
stop_spinner() {
  kill -9 "$spinner_pid"  # Stop the spinner loop
  printf "\r%s " "⠀"  # Print U+2800 (Braille Pattern Blank) and move to the next line
  display_message "$1"
}

display_message() {
  if [ -n "$1" ]; then
    echo -e "\n$1"
  else
    echo -e "\nTerminato!"
  fi
}

# -------------------------------------------------------------------------------------------------
# -------------------------------------- INIZIO CORPO SCRIPT --------------------------------------
# -------------------------------------------------------------------------------------------------

# ---------------------------------------- BACKUP DOCUMENTI ---------------------------------------
echo -n "🔄 Backup documenti contenuti nella cartella Documenti, "
# Verifica presenza funzione custom/standard su rsync e relativa configurazione
if rsync --help | grep -q "detect-renamed"; then
    echo -e "uso ${ORANGE}--detect-renamed${RESET} come funzione custom."
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Uso --detect-renamed come funzione custom." >> "$LOGFILE"
    EXTRA_FLAGS="--detect-renamed"
else
    echo -e "uso ${ORANGE}--fuzzy${RESET} come funzione standard."
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Uso --fuzzy$ come funzione standard." >> "$LOGFILE"
    EXTRA_FLAGS="--fuzzy"
fi

# BUG!!! TROVARE SOLUZIONE PER IL BACKUP OPPURE ELIMINARE LA SEZIONE
# Esecuzione backup con rsync documenti dichiarati nell'array
#declare -A backuploop=(
#    ["$HOME/Documenti/"]="$HOME/Documenti/Backup"
#    ["$HOME/Documenti/bash/*"]="$HOME/Documenti/Backup/bash"
#)

#for src in "${!backuploop[@]}"; do
#    dest="${backuploop[$src]}"

    # Nota: rsync gestisce meglio le cartelle che le wildcard dirette
#    echo -e "Backup locale da ${ORANGE}$src${RESET} a ${PURPLE}$dest${RESET}..."

#    mkdir -p "$dest"

    # Backup: raggruppa le opzioni e usa le variabili corrette
    # Nota: ho rimosso *.* e usato la cartella sorgente direttamente
#    rsync --backup --update --dirs --archive $EXTRA_FLAGS --progress "$src" "$dest" 2> >(while read -r line; do
#        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "$line"
#      done >> "$LOGFILE")
# done

# Sposta gli screenshot creati in COSMIC nella cartella desiderata
mv --verbose $HOME/Immagini/Screenshot* $HOME/Immagini/Schermate 2> >(while read -r line; do
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "$line"
done >> "$LOGFILE")

# ---------------------------------- COPIA DOCUMENTI SELEZIONATI ----------------------------------
# Definizione degli array contenenti i percorsi da copiare per utilizzo con Bash 4.0 e successivo
declare -A mappe=(
    ["$HOME/.local/share/Steam/userdata/"]="$HOME/Immagini/Steam/"
    ["$HOME/.local/share/Steam/steamapps/common/StellarBlade/Screenshots/"]="$HOME/Immagini/Steam/"
)

for src in "${!mappe[@]}"; do
    echo -e "Copia in locale da ${ORANGE}$src${RESET} a ${YELLOW}${mappe[$src]}${RESET}..."

    # Crea la directory di destinazione se non esiste
    mkdir -p "${mappe[$src]}"

    # Usa -print0 per gestire nomi file complessi e velocizzare il filtro
    find "$src" -maxdepth 2 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        ! \( -iname 'T_*' -o -name '*desktop*' -o -name '*thumb*' -o -name '*library*' -o -name '*strapper*' -o -name '*setting*' \) \
        -size +200k -print0 | while IFS= read -r -d '' file_path; do

        filename=$(basename "$file_path")
        dest_path="${mappe[$src]}$filename"

        # Copia/Link silenziando l'output standard ma loggando gli errori
        cp --link --update=older "$file_path" "$dest_path" 2> >(while read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') ERR: $line" >> "$LOGFILE"; done)
    done
done

# ----------------------------------- INIZIALIZZAZIONE DRYU-RUN -----------------------------------
#   prompt comando dry-run
echo -e "Copia locale completata.\n🔁 Avvio sync con rclone."
#   opera la scelta con ugum/gum/select
if command -v ugum >/dev/null 2>&1; then
    DR=$(ugum choose "Attivare dry-run" "Disattivare dry-run")
elif command -v gum >/dev/null 2>&1; then
    DR=$(gum choose "Attivare dry-run" "Disattivare dry-run")
else
    PS3="Dry-run: "
    select DR in "Attivare dry-run" "Disattivare dry-run"; do
        if [ -z "$DR" ]; then
            echo "Scelta non valida."
        else
            break
        fi
    done
fi

# Controllo sicurezza: se l'utente preme Esc/Ctrl+C con gum
if [ -z "$DR" ]; then
    trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Operazione annullata.'; exit" EXIT
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Operazione annullata in selezione dry-run, esco dallo script." >> "$LOGFILE"
    exit 1
fi

# Scelta dry-run (esecuzione senza elaborazione)
case $DR in
    "Disattivare dry-run")
        # 2.a.1 disabilita il dry-run, esegue i comandi - scelta utente positiva
        DRYRUN=""
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Disattivata funzione --dry-run per comando rclone, il servizio rclone avrà efficacia." >> "$LOGFILE";;
    *)
        # 2.a.2 abilita il dry-run in qualsiasi altro caso
        DRYRUN="--dry-run"
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Esecuzione in --dry-run per comando rclone, non verranno registrate modifiche." >> "$LOGFILE";;
esac

# --------------------------------------- SELEZIONE SERVIZIO --------------------------------------
if command -v ugum >/dev/null 2>&1; then
    TSYNC=$(ugum choose "Bisync" "Copy" "Resync" "Sync" "Download" "Quit")
elif command -v gum >/dev/null 2>&1; then
    TSYNC=$(gum choose "Bisync" "Copy" "Resync" "Sync" "Download" "Quit")
else
    PS3="Attività: "
    select TSYNC in "Bisync" "Copy" "Resync" "Sync" "Download" "Quit"; do
        if [ -z "$TSYNC" ]; then
            echo "Scelta non valida."
        else
            break
        fi
    done
fi

# Controllo sicurezza: se l'utente preme Esc/Ctrl+C con gum
if [ -z "$TSYNC" ]; then
    trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Operazione annullata.'; exit" EXIT
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Operazione annullata in selezione tipo sincronizzazione, esco dallo script." >> "$LOGFILE"
    exit 1
fi

# ----------------------------------- INIZIALIZZAZIONE SERVIZIO -----------------------------------
case $TSYNC in
    "Quit")
        # Esce dallo script
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Uscita dallo script su richiesta utente." >> "$LOGFILE"
        trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Uscita dallo script.'; exit" EXIT
        exit
        ;;
    "Sync") # Sincronizza il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
        echo -e "Attivazione funzione ${ORANGE}Sync${RESET}."
        for RCLONE_REMOTE in $(rclone listremotes | tr -d ':'); do
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Sincronizzazione con funzione sync di rclone su ${RCLONE_REMOTE}. Sovrascrive i file remoti con quelli locali incluse cancellazioni." >> "$LOGFILE"
            systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "**/$(basename "$LOGFILE")" --filter-from $CONFUP $HOME/ "${RCLONE_REMOTE}:/" 2>&1 | tee --append "$LOGFILE"
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato sync su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
        done
        ;;
    "Download") # Effettua il download integrale dal primo servizio remoto dichiarato in rclone secondo i filtri stabiliti in $CONFDW
        RCLONE_REMOTE=$(rclone listremotes | head -n 1 | tr -d ':')
        echo -e "Attivazione ${ORANGE}Download mediante funzione sync${RESET}."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Download da OneDrive mediante funzione sync di rclone. Sovrascrive i file locali con quelli remoti incluse cancellazioni!!!" >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Download rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "${LOGFILE}" --filter-from $CONFDW "${RCLONE_REMOTE}:/" $HOME/ 2>&1 | tee --append "$LOGFILE"
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato download da ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
        ;;
    "Bisync") # Bisync tiene aggiornati il serivizio remoto con i dati locali, anche cancellandoli
        echo -e "Attivazione funzione ${ORANGE}Bisync${RESET}."
        for RCLONE_REMOTE in $(rclone listremotes | tr -d ':'); do
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione bisync su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
            systemd-inhibit --what=idle:sleep --who="rclone" --why="Bisincronizzazione rclone in corso" rclone bisync $DRYRUN --force --metadata --log-level $LOGLVL --resilient --recover --max-lock 2m --conflict-resolve newer --max-age $VITA --exclude "**/$(basename "$LOGFILE")" --filter-from $CONFUP $HOME/ "${RCLONE_REMOTE}:/" 2>&1 | tee --append "$LOGFILE"
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato bisync su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
        done
        ;;
    "Resync") # Resync utilizza rclone bisync resync per effettuare la somme dei file presenti sul locale e sul remoto
        echo -e "Attivazione funzione ${ORANGE}Bisync con resync${RESET}."
        for RCLONE_REMOTE in $(rclone listremotes | tr -d ':'); do
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione bisync con resync su ${RCLONE_REMOTE} mediante rclone. Il risultato finale sarà la somma dei file locali e remoti." >> "$LOGFILE"
            systemd-inhibit --what=idle:sleep --who="rclone" --why="Bisincronizzazione rclone in corso" rclone bisync $DRYRUN --metadata --log-level $LOGLVL --resync --max-lock 2m --resync-mode newer --max-age $VITA --exclude "**/$(basename "$LOGFILE")" --filter-from $CONFUP $HOME/ "${RCLONE_REMOTE}:/" 2>&1 | tee --append "$LOGFILE"
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato resync su ${RCLONE_REMOTE} mediante rclone bisync." >> "$LOGFILE"
        done
        ;;
    *) # Copia il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
        echo -e "Attivazione funzione ${ORANGE}Copy${RESET}."
        for RCLONE_REMOTE in $(rclone listremotes | tr -d ':'); do
<<<<<<< Updated upstream
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione bisync con resync su ${RCLONE_REMOTE} mediante rclone. Il risultato finale sarà la somma dei file locali e remoti." >> "$LOGFILE"
            systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --log-level $LOGLVL --exclude "**/$(basename "$LOGFILE")" --filter-from $CONFUP $HOME/ "${RCLONE_REMOTE}:/" 2>&1 | tee --append "$LOGFILE"
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato bisync su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
=======
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione copy su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
            systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --log-level $LOGLVL --exclude "**/$(basename "$LOGFILE")" --filter-from $CONFUP $HOME/ "${RCLONE_REMOTE}:/" 2>&1 | tee --append "$LOGFILE"
            printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato copy su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
>>>>>>> Stashed changes
        done
        ;;
esac

printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Script rclone v. ${VERSIONE} build ${BUILD} terminato." >> "$LOGFILE"

# copia del file di log al termine di tutte le attività
start_spinner
for RCLONE_REMOTE in $(rclone listremotes | tr -d ':'); do
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione copy su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
    systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --log-level $LOGLVL "$LOGFILE" "${RCLONE_REMOTE}:/"
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Terminato copy su ${RCLONE_REMOTE} mediante rclone." >> "$LOGFILE"
done
stop_spinner

# Controlla se lo script è il processo leader della sessione (SID == PID)
if [ "$(ps -o sid= -p $$)" -eq "$$" ]; then
    echo -e "🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore. ${RED}È possibile chiudere la finestra.${RESET}"
else
    #   ripristino tput all'uscita
    trap "tput csr 0 $(($(tput lines) - 1)); clear ; echo '🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore.'; exit" EXIT
fi
