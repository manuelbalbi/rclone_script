#!/bin/bash
#   --- script di sincronizzazione con i servizi cloud utilizzando rclone ---
#   --- attivazione di backup e copia di file selezionati con rsync e cp ---

if [ -z "$BASH_VERSION" ]; then
    echo "Questo script richiede Bash."
    exit 1
fi

#   versione dello script
VERSIONE="2.1" #    VERSIONE    2.1
BETA="-b1" #        BETA        b1

#   configurazione file lettura e scrittura
LOGFILE="log_rclone_$VERSIONE$BETA.log"
CONFUP="rclone_conf.txt"
CONFDW="rclone_conf_mba.txt"
VITA="90d" # configurazione vita dei documenti da sincronizzare con bisync

#   livello di informazioni registrate da rclone nel file di log
#   seleziona il livello attivando/disattivando il commento
LOGLVL="INFO"
#LOGLVL="DEBUG"

#   definizione valori colori
GREEN="\e[38;2;97;187;70m"
YELLOW="\e[38;2;245;211;0m"
ORANGE="\e[38;2;247;148;29m"
RED="\e[38;2;226;31;38m"
PURPLE="\e[38;2;151;57;153m"
BLUE="\e[38;2;0;156;222m"
RESET="\e[0m"

#   configurazione estetica per gum/ugum mediante variabili d'ambiente
export GUM_CHOOSE_CURSOR=" "
export GUM_CHOOSE_CURSOR_FOREGROUND="#FF9F1C"
export GUM_CHOOSE_SELECTED_FOREGROUND="#FF9F1C"

#   configurazione spinner
# Define an array of Braille patterns for a spinner
six_dot_cell_pattern=("⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇")
eight_dot_cell_pattern=("⣾" "⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽")

# Set the pattern
braille_spinner=("${eight_dot_cell_pattern[@]}")

# Set the duration for each spinner frame (in seconds)
frame_duration=0.1

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

echo -e "$(date '+%Y-%m-%d %H:%M:%S') - AVVIO SCRIPT rclone $VERSIONE$BETA" >> $LOGFILE

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

#   controllo presenza dipendenze
REQUISITI=("rclone" "rsync")

for bin in "${REQUISITI[@]}"; do
    if ! command -v "$bin" &> /dev/null; then
        trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Script interrotto, non è installato il comando $bin.'; exit" EXIT
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - MANCA requisito $bin" >> $LOGFILE
        exit 1
    fi
done

# Backup dei documenti presenti nella cartella Documenti
echo -n "🔄 Backup documenti contenuti nella cartella Documenti, "
#   verifica presenza funzione custom/standard su rsync
if rsync --help | grep -q "detect-renamed"; then
    echo -e "uso ${ORANGE}--detect-renamed${RESET} come funzione custom."
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Uso rsync --detect-renamed come funzione custom" >> $LOGFILE
    EXTRA_FLAGS="--detect-renamed"
else
    echo -e "uso ${ORANGE}--fuzzy${RESET} come funzione standard."
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Uso rsync --fuzzy come funzione standard" >> $LOGFILE
    EXTRA_FLAGS="--fuzzy"
fi

# Esecuzione rsync documenti presenti in cartella Documenti e in Documenti/bash
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/*.* ~/Documenti/Backup 2> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/bash/*.* ~/Documenti/Backup/bash 2> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)

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

# 2.    --- configurazione rclone ---
DR="N"
DRYRUN="--dry-run"
TSYNC=""

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

# 2.a   scelta se disattivare il dry-run (esecuzione senza elaborazione)
case $DR in
    "Disattivare dry-run")
        # 2.a.1 disabilita il dry-run, esegue i comandi - scelta utente positiva
        DRYRUN=""
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Disattivata funzione --dry-run per comando rclone, il servizio rclone avrà efficacia." >> $LOGFILE;;
    *)
        # 2.a.2 abilita il dry-run in qualsiasi altro caso
        DRYRUN="--dry-run"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Esecuzione in --dry-run per comando rclone, non verranno registrate modifiche." >> $LOGFILE;;
esac

#   scelta livello di servizio
if command -v ugum >/dev/null 2>&1; then
    TSYNC=$(ugum choose "Copy" "Bisync" "Download" "Quit")
elif command -v gum >/dev/null 2>&1; then
    TSYNC=$(gum choose "Copy" "Bisync" "Download" "Quit")
else
    PS3="Attività: "
    select TSYNC in "Copy" "Bisync" "Download" "Quit"; do
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


# 2.b   scelta comado da attivare
case $TSYNC in
    "Quit")
        # 2.b.1 esce dallo script
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Uscita dallo script su richiesta utente." >> $LOGFILE
        trap "tput csr 0 $(($(tput lines) - 1)); clear; echo 'Uscita dallo script.'; exit" EXIT
        exit
        ;;
#    "Sync")
#        # 2.b.2 sincronizza il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
#        echo -e "Attivazione funzione ${ORANGE}Sync${RESET}."
#        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Sincronizzazione con funzione sync di rclone su OneDrive. Sovrascrive i file remoti con quelli locali incluse cancellazioni." >> $LOGFILE
#        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/
#        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Sincronizzazione con funzione sync di rclone su Google Drive. Sovrascrive i file remoti con quelli locali incluse cancellazioni." >> $LOGFILE
#        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/
#        ;;
    "Download")
        # 2.b.3 effettua il download integrale dal servizio remoto OneDrive secondo i filtri stabiliti in $CONFDW
        echo -e "Attivazione ${ORANGE}Download mediante funzione sync${RESET}."
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Download da OneDrive mediante funzione sync di rclone. Sovrascrive i file locali con quelli remoti incluse cancellazioni!!!" >> $LOGFILE
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Download rclone in corso" rclone sync $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFDW OneDrive:/Bazzite/ $HOME/
        ;;
    "Bisync")
        # 2.b.4 effettua la bisincronizzazione da OneDrive, quindi avvia la sincronizzazione con Google il tutto con i filtri di $CONFUP
        echo -e "Attivazione funzione ${ORANGE}Bisync${RESET}."
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Attivazione funzione bisync su OneDrive mediante rclone." >> $LOGFILE
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Bisincronizzazione rclone in corso" rclone bisync $DRYRUN --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --recover --resync-mode newer --max-age $VITA --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Attivazione funzione sync su Google Drive mediante rclone." >> $LOGFILE
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Sincronizzazione rclone in corso" rclone sync $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/
        ;;
    *)
        # 2.b.5 copia il contenuto dei filtri dichiarati in $CONFUP sui servizi remoti
        echo -e "Attivazione funzione ${ORANGE}Copy${RESET}."
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Attivazione funzione copy di rclone su OneDrive." >> $LOGFILE
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ OneDrive:/Bazzite/
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Attivazione funzione copy di rclone su Google Drive." >> $LOGFILE
        systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copy $DRYRUN --update --metadata --progress --log-level $LOGLVL --log-file=$LOGFILE --exclude "$LOGFILE" --filter-from $CONFUP $HOME/ Google:/
        ;;
esac

echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Script rclone $VERSIONE$BETA terminato.\n" >> $LOGFILE

# copia del file di log al termine di tutte le attività
start_spinner
systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copyto $DRYRUN --update --metadata $LOGFILE OneDrive:/Bazzite/Documenti/$LOGFILE
systemd-inhibit --what=idle:sleep --who="rclone" --why="Copia rclone in corso" rclone copyto $DRYRUN --update --metadata $LOGFILE Google:/Documenti/$LOGFILE
stop_spinner

# Controlla se lo script è il processo leader della sessione (SID == PID)
if [ "$(ps -o sid= -p $$)" -eq "$$" ]; then
    echo -e "🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore. ${RED}È possibile chiudere la finestra.${RESET}"
else
    #   ripristino tput all'uscita
    trap "tput csr 0 $(($(tput lines) - 1)); clear; echo '🔁 Rclone concluso. Consultare il file di log: $LOGFILE per eventuali messaggi di errore.'; exit" EXIT
fi
