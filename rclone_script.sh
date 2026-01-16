#!/bin/bash
#   --- script di sincronizzazione con i servizi cloud utilizzando rclone ---
#   --- attivazione di backup e copia di file selezionati con rsync e cp ---

#   versione dello script
VERSIONE="2.0" # prima beta dello script rivisto
VERSIONE="2.0.1" # aggiunto spinner per attesa copyto finale
VERSIONE="2.0.2" # aggiunta copia immaigni generate da Stability Matrix
VERSIONE="2.0.3" # aggiunta controlli in uscita per identificare l'esecuzione dal terminale o dal Desktop Enviroment
VERSIONE="2.0.4" # introduzione parametro --max-age con variabile $VITA per impostare il limite di vecchiaia con bisync e disattivazione funzione sync (sul remoto OneDrive ci sono elementi non sincronizzati sul locale)

#   configurazione file lettura e scrittura
LOGFILE="log_rclone_$VERSIONE.log"
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

echo -e "$(date '+%Y-%m-%d %H:%M:%S') - AVVIO SCRIPT rclone $VERSIONE" >> $LOGFILE

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
echo -e "${BLUE}                                                                     ⠉ ${RESET} di Manuel Balbi - \e[1;37mv.$VERSIONE${RESET}"
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

#   backup dei documenti presenti nella cartella Documenti
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
#   esecuzione rsync documenti presenti in cartella Documenti e in Documenti/bash
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/*.* ~/Documenti/Backup 2> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)
rsync --backup --update --archive $EXTRA_FLAGS --progress ~/Documenti/bash/*.* ~/Documenti/Backup/bash 2> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)

# 1.    --- copia delle immagini di Steam nella cartella Immagini ---
# 1.a   configurazione dei percorsi di Steam, se esistente
SOURCE_DIR="$HOME/.local/share/Steam/userdata/"

if [ -d "$SOURCE_DIR" ]; then
    DEST_DIR="$HOME/Immagini/Steam/"
    file_path=

    # 1.b   crea la cartella di destinazione se inesistente
    mkdir -p "$DEST_DIR"

    echo -e "Copia locale da: ${ORANGE}$SOURCE_DIR${RESET} a: ${YELLOW}$DEST_DIR${RESET}"

    # 1.c   Usa find per cercare ricorsivamente i file, -type f: cerca solo file
    find "$SOURCE_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) ! \( -iname 'T_*' -o -name '*desktop*' -o -name '*thumb*' -o -name '*library*' -o -name '*strapper*' -o -name '*setting*' \) -size +200k | while read -r file_path; do

        # 1.c.1 estrai solo il nome del file (es. "immagine_001.jpg") dal percorso completo
        filename=$(basename "$file_path")

        # 1.c.2 definisci il percorso completo del file di destinazione
        dest_path="$DEST_DIR$filename"

        # 1.c.3 copia il file con opzione --link in modo da preservare i metadati del file originale
        # echo "Copia di $file_path in $dest_path"
        cp --link --update=older "$file_path" "$dest_path" &> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)
    done
fi


# 1.d   configurazione dei percorsi dedicati a StellarBlade, se esistente
SOURCE_DIR="$HOME/.local/share/Steam/steamapps/common/StellarBlade/Screenshots/"

if [ -d "$SOURCE_DIR" ]; then
    DEST_DIR="$HOME/Immagini/Steam/"
    file_path=

    echo -e "Spostamento locale da: ${ORANGE}$SOURCE_DIR${RESET} a: ${YELLOW}$DEST_DIR${RESET}"

    # 1.e   Usa find per cercare ricorsivamente i file, -type f: cerca solo file
    find "$SOURCE_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -size +200k | while read -r file_path; do

        # 1.e.1 estrai solo il nome del file (es. "immagine_001.jpg") dal percorso completo
        filename=$(basename "$file_path")

        # 1.e.2 definisci il percorso completo del file di destinazione
        dest_path="$DEST_DIR$filename"

        # 1.e.3 muove il file con opzione --link in modo da preservare i metadati del file originale
        # echo "Muovo il $file_path in $dest_path"
        mv --update=older "$file_path" "$dest_path" 2> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)
    done
fi

# 1.f   configurazione dei percorsi dedicati alla generazione per inferenza con Stability Matrix
SOURCE_DIR="$HOME/AppImages/Data/Images/Inference/"

if [ -d "$SOURCE_DIR" ]; then
    DEST_DIR="$HOME/Immagini/.AI 🤖/Inference/"
    file_path=

    # 1.g   crea la cartella di destinazione se inesistente
    mkdir -p "$DEST_DIR"

    echo -e "Copia locale da: ${ORANGE}$SOURCE_DIR${RESET} a: ${YELLOW}$DEST_DIR${RESET}"

    # 1.h   Usa find per cercare ricorsivamente i file, -type f: cerca solo file
    find "$SOURCE_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) ! \( -iname 'T_*' -o -name '*desktop*' -o -name '*thumb*' -o -name '*library*' -o -name '*strapper*' -o -name '*setting*' \) -size +200k | while read -r file_path; do

        # 1.h.1 estrai solo il nome del file (es. "immagine_001.jpg") dal percorso completo
        filename=$(basename "$file_path")

        # 1.h.2 definisci il percorso completo del file di destinazione
        dest_path="$DEST_DIR$filename"

        # 1.h.3 copia il file con opzione --link in modo da preservare i metadati del file originale
        # echo "Copia di $file_path in $dest_path"
        cp --link --update=older "$file_path" "$dest_path" &> >(while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> $LOGFILE)
    done
fi

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

echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Script rclone $VERSIONE terminato.\n" >> $LOGFILE

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
