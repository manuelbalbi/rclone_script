#!/bin/bash

# Importing script global variables
cd "$(dirname "$0")"
source "$(dirname "$0")/vars.sh"

# Create config and install directory
mkdir -p "$INSTALLDIR"

rsync --archive --update --backup --progress --suffix=_$(date +%Y%m%d) "${INSTALLDIR}/${CONF_DIR}/" "${INSTALLDIR}/${CONF_DIR}_bak"


# Delete logs older than $TFINDFLUSH
find "$INSTALLDIR" -type f -name "*log*" -mtime +"$TFINDFLUSH" -delete

# Estrai in cartella temporanea
TEMP_EXTRACT="$INSTALLDIR/tmp"
rm -rf "$TEMP_EXTRACT" # Pulisce residui precedenti
mkdir -p "$TEMP_EXTRACT"
echo "Download in corso..."
curl -fsL "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.zip" -o "$INSTALLDIR/$TEMP_FILE"
unzip -qo "$INSTALLDIR/$TEMP_FILE" -d "$TEMP_EXTRACT"

SOURCE_DIR="$TEMP_EXTRACT/$REPO_NAME-$BRANCH"

mv -f "$SOURCE_DIR/" "$INSTALLDIR/"

rm -rdf "$TEMP_FILE" "$TEMP_EXTRACT"

echo "Tutti i file sono stati elaborati correttamente."

chmod +x rclone_script.sh
sudo ln -s "$INSTALLDIR/rclone_script.sh" /usr/local/bin/rclone-script
chmod +x rclone_daemon.sh

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
