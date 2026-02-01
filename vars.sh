# Configurazione per repository GitHub pubblico
GITUSER="manuelbalbi"
GITREPO="rclone_script"
GITFILE="rclone_script.sh"
UPDATE_URL="https://raw.githubusercontent.com/${GITUSER}/${GITREPO}/refs/heads/main/${GITFILE}" # https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh
SCRIPT_PATH="$(readlink -f "$0")"

# Configurazione percorsi, file di log, file di configurazione e tempi di vita dei documenti di sincronizzazione e di pulizia backlog
LOGDIR="$HOME/.config/rclone_script"
LOGNAME="$(date +%F)_log_rclone_${BUILD}.log"
LOGFILE="${LOGDIR}/${LOGNAME}"
CONF_FILE_UP="rclone_script_upload.conf"
CONF_FILE_DOWN="rclone_script_download.conf"
CONFUP="${LOGDIR}/${CONF_FILE_UP}"
CONFDW="${LOGDIR}/${CONF_FILE_DOWN}"
CONFSERVICE="$HOME/.config/systemd/user/rclone-bisync.service"
CONFTIMER="$HOME/.config/systemd/user/rclone-bisync.timer"
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
six_dot_cell_pattern=("⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇")
eight_dot_cell_pattern=("⣾" "⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽")

# Set the pattern
braille_spinner=("${eight_dot_cell_pattern[@]}")

# Set the duration for each spinner frame (in seconds)
frame_duration=0.1
