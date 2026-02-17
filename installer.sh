#!/bin/bash

REPO_OWNER="manuelbalbi"
REPO_NAME="rclone_script"
BRANCH="main"
GITFILE="vars.sh"
GITPACKAGE=("var.sh" "rclone_script.sh")
UPDATE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/refs/heads/main/${GITFILE}" # https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh
SCRIPT_PATH="$(readlink -f "$0")"

# Configurazione percorsi, file di log, file di configurazione e tempi di vita dei documenti di sincronizzazione e di pulizia backlog
INSTALLDIR="$HOME/.config/rclone_script"
TEMP_FILE="temp.zip"
CONF_FILE_UP="rclone_script_upload.conf"
CONF_FILE_DOWN="rclone_script_download.conf"
CONF_DIR="config_files"
CONFUP="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_UP}"
CONFDW="${INSTALLDIR}/${CONF_DIR}/${CONF_FILE_DOWN}"

mkdir -p "${INSTALLDIR}"
mkdir -p "${INSTALLDIR}/${CONF_DIR}"

# Estrai in cartella temporanea
echo "Download in corso..."
curl --fail --location --verbose "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.zip" -o "$INSTALLDIR/$TEMP_FILE"

unzip -o "$INSTALLDIR/$TEMP_FILE" -d "$INSTALLDIR"

# Usiamo il wildcard * per essere sicuri di beccare la cartella estratta
mv -f "$INSTALLDIR/$REPO_NAME-$BRANCH/"* "$INSTALLDIR/" 2>/dev/null || mv -f "$INSTALLDIR/$REPO_NAME-main/"* "$INSTALLDIR/"

rm -rf "$INSTALLDIR/$TEMP_FILE" "$INSTALLDIR/$REPO_NAME-$BRANCH" "$INSTALLDIR/$REPO_NAME-main"

chmod +x "$INSTALLDIR/rclone_script.sh"
sudo ln -sf "$INSTALLDIR/rclone_script.sh" /usr/local/bin/rclone-script

echo "Installazione completata con successo."

# chmod +x rclone_daemon.sh

# -------------------------------------------------------------------------------------------------
# Create missing config files
if [ ! -f "$CONFUP" ]; then
    echo -e "${ORANGE}CREAZIONE:${RESET} $CONF_FILE_UP"
    cat <<EOF > "$CONFUP"
# rclone_script default configuration created for v. ${VERSIONE} build ${BUILD} file $CONF_FILE_UP
# Please refer to https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for configuring rsync filters

# Hidden paths
- .*{/**,}

# Including
- Documenti/backup/**
+ Documenti/**
+ Games/**
- Immagini/Windows/**
- Immagini/2025-12-22 milena smash cake/**
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

# Hidden paths
+ .config/rclone_script/**
- .*{/**,}

# Including
- Documenti/backup/**
+ Documenti/**
+ Games/**
- Immagini/Windows/**
- Immagini/2025-12-22 milena smash cake/**
+ Immagini/**
+ Musica/**
+ Pubblici/**
+ Scrivania/**
- Video/Radeon ReLive/**
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
