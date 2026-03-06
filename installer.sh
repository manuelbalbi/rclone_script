#!/bin/bash
#
# rclone-script installer
# https://github.com/manuelbalbi/rclone_script
#

set -e # interrompe immediatamente al primo errore

# Funzione CLEANUP per pulire i file di log
cleanup() {
    rm -rf "$INSTALLDIR/$TEMP_FILE" "$INSTALLDIR/$REPO_NAME-$BRANCH" "$INSTALLDIR/$REPO_NAME-main"
}
trap cleanup EXIT # Esegue la funzione CLEANUP in caso di chiusura inaspettata dello script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

REPO_NAME="rclone_script"
BRANCH="main"
UPDATE_URL="hhttps://raw.githubusercontent.com/manuelbalbi/${REPO_NAME}/refs/heads/${BRANCH}/rclone_script.sh"
SCRIPT_PATH="$(readlink -f "$0")"

# Configurazione percorsi, file di log, file di configurazione e tempi di vita dei documenti di sincronizzazione e di pulizia backlog
INSTALLDIR="$HOME/.config/rclone_script"
TEMP_FILE="temp.zip"
CONF_FILE_UP="rclone_script_upload.conf"
CONF_FILE_DOWN="rclone_script_download.conf"
CONF_DIR="config_files"
CONFUP="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_UP}"
CONFDW="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_DOWN}"

# funzioni di logging
info() {
    echo -e "${BLUE}==>${NC} ${BOLD}$1${NC}"
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "$1" >> "$LOGFILE"
}

success() {
    echo -e "${GREEN}==>${NC} ${BOLD}$1${NC}"
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "INFO" "$1" >> "$LOGFILE"
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $1"
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "WARN" "$1" >> "$LOGFILE"
}

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    printf "%(%Y-%m-%d)T %(%H:%M:%S)T %-6s: %s\n" -1 -1 "ERROR" "$1" >> "$LOGFILE"
    exit 1
}

command_exists() {
    command -v "$1" &> /dev/null
}

if [ -d "${INSTALLDIR}" ]; then
    info "La cartella esiste già: ${INSTALLDIR}"
else
    mkdir -p "${INSTALLDIR}"
    success "Cartella creata con successo: ${INSTALLDIR}"
fi

if [ -d "${INSTALLDIR}/${CONF_DIR}" ]; then
    info "La cartella esiste già: ${INSTALLDIR}/${CONF_DIR}"
else
    mkdir -p "${INSTALLDIR}/${CONF_DIR}"
    success "Cartella creata con successo: ${INSTALLDIR}/${CONF_DIR}"
fi

# Estrai in cartella temporanea
if ! command_exists curl; then
    error "${BOLD}curl${NC} non è installato, prima di procedere è necessario installare curl."
fi

info "Download in corso..."
curl --fail --location --verbose "https://github.com/manuelbalbi/${REPO_NAME}/archive/refs/heads/${BRANCH}.zip" -o "${INSTALLDIR}/${TEMP_FILE}"

if ! command_exists unzip; then
    error "${BOLD}unzip${NC} non è installato, prima di procedere è necessario installare unzip."
fi
unzip -o "${INSTALLDIR}/${TEMP_FILE}" -d "${INSTALLDIR}"

# Usiamo il wildcard * per essere sicuri di beccare la cartella estratta
mv -f "${INSTALLDIR}/${REPO_NAME}-${BRANCH}/"* "${INSTALLDIR}/" 2>/dev/null || mv -f "${INSTALLDIR}/${REPO_NAME}-main/"* "${INSTALLDIR}/"

cleanup

chmod +x "${INSTALLDIR}/rclone_script.sh"

SUDO=""
if [ "$(id -u)" -ne 0 ] && command_exists sudo; then
    SUDO="sudo"
fi
$SUDO ln -sf "${INSTALLDIR}/rclone_script.sh" /usr/local/bin/rclone-script

success "Installazione completata con successo."

# -------------------------------------------------------------------------------------------------
# Create missing config files
if [ ! -f "$CONFUP" ]; then
    info "CREAZIONE: ${CONF_FILE_UP}"
    cat <<EOF > "$CONFUP"
# rclone_script default configuration created for v. ${VERSIONE} build ${BUILD} file ${CONF_FILE_UP}
# Please refer to https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for configuring rsync filters

# Hidden paths
- .*{/**,}

# Including
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
    info "CREAZIONE: ${CONF_FILE_DOWN}"
    cat <<EOF > "$CONFDW"
# rclone_script default configuration created for v. ${VERSIONE} build ${BUILD} file ${CONF_FILE_UP}
# Please refer to https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for configuring rsync filters

# Hidden paths
+ .config/rclone_script/**
- .*{/**,}

# Including
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
)

for bin in "${REQUISITI[@]}"; do
    if ! command -v "$bin" &> /dev/null; then
        error "Script interrotto, manca requisito $bin"
        exit 1
    fi
done
