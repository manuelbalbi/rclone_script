#!/bin/bash
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# --------------- SCRIPT DI SINCRONIZZAZIONE CON I SERVIZI CLOUD UTILIZZANDO rclone ---------------
# ---------------- ATTIVAZIONE DI BACKUP E COPIA DI FILE SELEZIONATI CON rsync / cp ---------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# --------------------------------- INIZIO DICHIARAZIONE VARIABILI --------------------------------
# Dichiarazione versione script
# $VERSIONE contiene la dichiarazione della revisione
# $BETA indica se si tratta di una versione beta, nel caso di versione finale la variabile $BETA=""
# $VERSION contiene la versione in formato data invertita per effettuare il controllo per l'autoaggiornamento. Il valore è indipendente da $VERSIONE e $BETA
VERSIONE="2.2" #    VERSIONE    2.2
BETA="-b1" #        BETA        1
# Versione per confronto aggiornamento su GitHub
VERSION=20260128

# Configurazione per repository GitHub pubblico
USER="manuelbalbi"
REPO="rclone_script"
FILE="rclone_script.sh"
UPDATE_URL="https://raw.githubusercontent.com/${USER}/${REPO}/refs/heads/main/${FILE}" # https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh
SCRIPT_PATH="$(readlink -f "$0")"

# Configurazione file lettura e scrittura
LOGDIR="$HOME/.config/rclone_script"
LOGNAME="$(date +%F)_log_rclone_${VERSIONE}${BETA}.log"
LOGFILE="${LOGDIR}/${LOGNAME}"
CONF_FILE_UP="rclone_script_upload.conf"
CONF_FILE_DOWN="rclone_script_download.conf"
CONFUP="${LOGDIR}/${CONF_FILE_UP}"
CONFDW="${LOGDIR}/${CONF_FILE_DOWN}"
VITA="90d" # configurazione vita dei documenti da sincronizzare con bisync
TFINDFLUSH="30" # tempo in giorni per -mtime su comando find per cancellazione file di log / pulizia backlog vecchio
LOCKFILEDIR="$HOME/.cache/rclone/bisync/" # riferimento a https://rclone.org/bisync/#lock-file

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
# Define an array of Braille patterns for a spinner
six_dot_cell_pattern=("⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇")
eight_dot_cell_pattern=("⣾" "⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽")

# Set the pattern
braille_spinner=("${eight_dot_cell_pattern[@]}")

# Set the duration for each spinner frame (in seconds)
frame_duration=0.1

# -------------------------------------------------------------------------------------------------
# ---------------------------------------- INIZIO CONTROLLI ---------------------------------------

printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "--- AVVIO SCRIPT rclone $VERSIONE$BETA -------------------------------------------------------------" >> "$LOGFILE"

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
echo -e "${BLUE}                                                                     ⠉ ${RESET} di Manuel Balbi - \e[1;37mv.$VERSIONE$BETA${RESET}"
tput cup 9 0

# Controllo versione bash
if [ -z "$BASH_VERSION" ]; then
    echo "Questo script richiede Bash."
    exit 1
fi

# Creo la cartella per il log se non già esistente (uso le virgolette per sicurezza)
mkdir -p "$LOGDIR"

# Cerco e cancello file di log più vecchi di $TFINDFLUSH
find "$LOGDIR" -type f -name "*log*" -mtime +"$TFINDFLUSH" -delete

# --- LOGICA DI AGGIORNAMENTO ---
echo "Controllo versione in corso da ${UPDATE_URL}..."
printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Verifica versione script da ${UPDATE_URL}..." >> "$LOGFILE"

# Estrae la riga VERSION dal file remoto su GitHub
REMOTE_VERSION=$(curl -sL "$UPDATE_URL" | grep "^VERSION=" | head -1 | cut -d'=' -f2)

if [ -z "$REMOTE_VERSION" ]; then
    ACTION="error"
elif [ "$REMOTE_VERSION" -gt "$VERSION" ]; then # -gt greater than
    ACTION="update"
elif [ "$REMOTE_VERSION" -lt "$VERSION" ]; then # -lt less than
    ACTION="dev_mode"
else
    ACTION="skip"
fi

case "$ACTION" in
    "update")
        echo "Versione $REMOTE_VERSION disponibile. Aggiornamento in corso..."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Disponibile versione $REMOTE_VERSION, aggiorno..." >> "$LOGFILE"
        curl -sL "$UPDATE_URL" -o "${SCRIPT_PATH}.tmp" && mv "${SCRIPT_PATH}.tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        exec "$SCRIPT_PATH" "$@" # esegue lo script sostituendo il processo in esecuzione con il medesimo PID e uccidendo l'attuale
        ;;
    "dev_mode")
        echo "Stai usando una versione locale ($VERSION) più recente di GitHub ($REMOTE_VERSION)."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Versione locale ($VERSION) più recente di GitHub ($REMOTE_VERSION)." >> "$LOGFILE"
        ;;
    "error")
        echo "Errore: Impossibile determinare la versione da GitHub."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "AVVISO" "Errore nel determinare la versione da GitHub." >> "$LOGFILE"
        ;;
    "skip"|*)
        echo "Script già aggiornato (v$VERSION)."
        printf "\n%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Versione locale ($VERSION), versione GitHub ($REMOTE_VERSION)." >> "$LOGFILE"
        ;;
esac

# -------------------------------------------------------------------------------------------------
# Creazione file di configurazione rclone (Upload)
if [ ! -f "$CONFUP" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_UP"
    cat <<EOF > "$CONFUP"
# Configurazione predefinita per rclone_script $VERSIONE$BETA parametro '--filter-from' file $CONF_FILE_UP
# Configura aggiungendo o cancellando righe con riferimento a https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file

# 1. Inclusioni specifiche nascoste
+ Immagini/.AI 🤖/**
+ Immagini/.instagram/**
+ Immagini/.chflags hidden path/**
+ Video/.Grok/**
+ Documenti/GitHub/**

# 2. Esclusione generale dei file/cartelle nascoste
- .*{/**,}

# 3. Altre esclusioni e inclusioni standard
- Documenti/Backup/**
+ Documenti/**
- Games/Heroic/**
+ Games/**
- Immagini/Windows/**
- Immagini/2025-12-22 milena smash cake/
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
# Configurazione predefinita per rclone_script $VERSIONE$BETA parametro '--filter-from' file $CONF_FILE_DOWN
# Configura aggiungendo o cancellando righe con riferimento a https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file

# 1. Inclusioni specifiche anche nascoste
+ Immagini/.AI 🤖/**
+ Immagini/.instagram/**
+ Immagini/.chflags hidden path/**
+ Video/.Grok/**
+ Documenti/GitHub/**

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
# -------------------------------------------------------------------------------------------------
# -------------------------------------- INIZIO CORPO SCRIPT --------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# ---------------------------------------- BACKUP DOCUMENTI ---------------------------------------
echo -n "🔄 Backup documenti contenuti nella cartella Documenti, "
#   verifica presenza funzione custom/standard su rsync
if rsync --help | grep -q "detect-renamed"; then
    echo -e "uso ${ORANGE}--detect-renamed${RESET} come funzione custom."
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Uso --detect-renamed come funzione custom." >> "$LOGFILE"
    EXTRA_FLAGS="--detect-renamed"
else
    echo -e "uso ${ORANGE}--fuzzy${RESET} come funzione standard."
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Uso --fuzzy$ come funzione custom." >> "$LOGFILE"
    EXTRA_FLAGS="--fuzzy"
fi

# Esecuzione backup con rsync documenti presenti in cartella Documenti e in Documenti/bash
# Documenti
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/*.* ~/Documenti/Backup 2> >(while read -r line; do
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "NOTICE" "$line"
done >> "$LOGFILE")
# Documenti/bash
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/bash/*.* ~/Documenti/Backup/bash 2> >(while read -r line; do
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "NOTICE" "$line"
done >> "$LOGFILE")
# Sposta gli screenshot creati in COSMIC nella cartella desiderata
mv --verbose $HOME/Immagini/Screenshot* $HOME/Immagini/Schermate 2> >(while read -r line; do
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "NOTICE" "$line"
done >> "$LOGFILE")

# ---------------------------------- COPIA DOCUMENTI SELEZIONATI ----------------------------------
# Definizione degli array contenenti i percorsi da copiare per utilizzo con Bash 4.0 e successivo
declare -A mappe=(
    ["$HOME/.local/share/Steam/userdata/"]="$HOME/Immagini/Steam/"
    ["$HOME/.local/share/Steam/steamapps/common/StellarBlade/Screenshots/"]="$HOME/Immagini/Steam/"
    ["$HOME/AppImages/Data/Images/Inference/"]="$HOME/Immagini/.AI 🤖/Inference/"
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
    "Sync") # questo codice si attiva solo con il comando ugum, disponibile esclusivamente su Bazzite
        # 2.b.2 sincronizza il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
        echo -e "Attivazione funzione ${ORANGE}Sync${RESET}."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO!" "Sincronizzazione con funzione sync di rclone su OneDrive. Sovrascrive i file remoti con quelli locali incluse cancellazioni." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/ 2>&1 | tee --append "$LOGFILE"
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO!" "Sincronizzazione con funzione sync di rclone su Google Drive. Sovrascrive i file remoti con quelli locali incluse cancellazioni." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/ 2>&1 | tee --append "$LOGFILE"
        ;;
    "Download")
        # 2.b.3 effettua il download integrale dal servizio remoto OneDrive secondo i filtri stabiliti in $CONFDW
        echo -e "Attivazione ${ORANGE}Download mediante funzione sync${RESET}."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO!!" "Download da OneDrive mediante funzione sync di rclone. Sovrascrive i file locali con quelli remoti incluse cancellazioni!!!" >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Download rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFDW OneDrive:/Bazzite/ $HOME/ 2>&1 | tee --append "$LOGFILE"
        ;;
    "Bisync")
        # 2.b.4 effettua la bisincronizzazione da OneDrive, quindi avvia la sincronizzazione con Google il tutto con i filtri di $CONFUP
        echo -e "Attivazione funzione ${ORANGE}Bisync${RESET}."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione bisync su OneDrive mediante rclone." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Bisincronizzazione rclone in corso" rclone bisync $DRYRUN --force --metadata --log-level $LOGLVL --resilient --recover --max-lock 2m --conflict-resolve newer --max-age $VITA --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/ 2>&1 | tee --append "$LOGFILE"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - " >> $LOGFILE
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO!" "Attivazione funzione sync su Google Drive mediante rclone. In caso di errore sulla sincronizzazione prcedente i dati potrebbe andare persi!" >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/ 2>&1 | tee --append "$LOGFILE"
        ;;
    "Resync")
        # 2.b.5 effettua la bisincronizzazione da OneDrive, quindi avvia la sincronizzazione con Google il tutto con i filtri di $CONFUP con funzione RESYNC - da utilizzare alla prima risincronizzazione
        echo -e "Attivazione funzione ${ORANGE}Bisync con resync${RESET}."
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - " >> $LOGFILE
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione bisync con resync su OneDrive mediante rclone. Il risultato finale sarà la somma dei file locali e remoti." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Bisincronizzazione rclone in corso" rclone bisync $DRYRUN --metadata --log-level $LOGLVL --resync --resync-mode newer --max-age $VITA --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/ 2>&1 | tee --append "$LOGFILE"
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO!" "Attivazione funzione sync su Google Drive mediante rclone. In caso di errore sulla sincronizzazione prcedente i dati potrebbe andare persi!" >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/ 2>&1 | tee --append "$LOGFILE"
        ;;
    *)
        # 2.b.6 copia il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
        echo -e "Attivazione funzione ${ORANGE}Copy${RESET}."
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione copy di rclone su OneDrive." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/ 2>&1 | tee --append "$LOGFILE"
        printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Attivazione funzione copy di rclone su Google Drive." >> "$LOGFILE"
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --log-level $LOGLVL --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/ 2>&1 | tee --append "$LOGFILE"
        ;;
esac

printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "Script rclone $VERSIONE$BETA terminato." >> "$LOGFILE"

# copia del file di log al termine di tutte le attività
start_spinner
systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copyto $DRYRUN --update --metadata "$LOGFILE" OneDrive:/Bazzite/Documenti/$LOGFILE
systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copyto $DRYRUN --update --metadata "$LOGFILE" Google:/Documenti/$LOGFILE
stop_spinner

# Controlla se lo script è il processo leader della sessione (SID == PID)
if [ "$(ps -o sid= -p $$)" -eq "$$" ]; then
    echo -e "🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore. ${RED}È possibile chiudere la finestra.${RESET}"
else
    #   ripristino tput all'uscita
    trap "tput csr 0 $(($(tput lines) - 1)); clear; echo '🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore.'; exit" EXIT
fi
