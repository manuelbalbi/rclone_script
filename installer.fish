#!/usr/bin/fish

function installer
    # rclone-script installer per Fish Shell
    # https://github.com/manuelbalbi/rclone_script

    # Configurazione percorsi
    set -g git_repo_name "rclone_script"
    set -g git_repo_brach "fish"
    set -g rclone_script_config_path "$HOME/.config/rclone_script"
    set -g temp_file "temp.zip"
    set -g config_files_path "config_files"
    set -g config_file_upload "rclone_script_upload.conf"
    set -g config_file_upload_path "$rclone_script_config_path/$config_files_path/$config_file_upload"
    set -g install_path "$HOME/.config/fish/functions/"

    # Funzioni di logging con set_color (più nativo in Fish)
    function info
        echo -e (set_color blue)"==>"(set_color normal) (set_color --bold)"$argv"(set_color normal)
    end

    function success
        echo -e (set_color green)"==>"(set_color normal) (set_color --bold)"$argv"(set_color normal)
    end

    function warn
        echo -e (set_color yellow)"Warning:"(set_color normal) "$argv"
    end

    function error
        echo -e (set_color red)"Error:"(set_color normal) "$argv" >&2
        return 1
    end

    # Cleanup function
    function on_exit --on-event fish_exit
        rm -rf "$rclone_script_config_path/$temp_file" "$rclone_script_config_path/$git_repo_name-$git_repo_brach" "$rclone_script_config_path/$git_repo_name-$git_repo_brach"
    end

    # --- Inizio Script ---

    # Controllo/Creazione cartelle
    for dir in "$rclone_script_config_path" "$rclone_script_config_path/$config_files_path"
        if test -d "$dir"
            info "La cartella esiste già: $dir"
        else
            if mkdir -p "$dir"
                success "Cartella creata con successo: $dir"
            else
                error "Impossibile creare la cartella: $dir"
            end
        end
    end

    # Controllo presenza dipendenze
    set dependecies_needed rclone curl unzip

    for bin in $dependecies_needed
        if not type -q $bin
            warn "Manca $bin. Tento l'installazione..."
            sudo pacman -Sy --needed $dependecies_needed
            break # Esce dal ciclo dopo aver lanciato pacman una volta
        end
    end

    info "Download in corso..."
    curl --fail --location "https://github.com/manuelbalbi/$git_repo_name/archive/refs/heads/$git_repo_brach.zip" -o "$rclone_script_config_path/$temp_file"

    unzip -o "$rclone_script_config_path/$temp_file" -d $rclone_script_config_path

    # Spostamento file (gestione wildcard)
    if test -d "$rclone_script_config_path/$git_repo_name-$git_repo_brach"
        mv -f "$rclone_script_config_path/$git_repo_name-$git_repo_brach/"* "$rclone_script_config_path/"
    else if test -d "$rclone_script_config_path/$git_repo_name-$git_repo_brach"
        mv -f "$rclone_script_config_path/$git_repo_name-$git_repo_brach/"* "$rclone_script_config_path/"
    end

    # Assicurati che la cartella funzioni esista
    mkdir -p ~/.config/fish/functions/; and info "Cartella funzioni esistente."

    # Copia lo script
    cp --force --link "$rclone_script_config_path/rclone_script.fish" "$install_path/rclone_script.fish"; and success "Installazione script di fish completata con successo."

    # --- Creazione file di configurazione (HereDocs in Fish) ---
    if not test -f "$config_file_upload_path"
        info "CREAZIONE: $config_file_upload"
        printf "# rclone_script default configuration\n\n- .*{/**,}\n\n+ Documenti/**\n+ Games/**\n+ Immagini/**\n+ Musica/**\n+ Pubblici/**\n+ Scrivania/**\n+ Video/**\n\n- *" > $config_file_upload_path; and info "File $config_file_upload creato correttamente."
    end

end
