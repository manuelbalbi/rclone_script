#!/usr/bin/fish

# --- Variabili di Versione ---
set script_version "3.0"
#                  ⡤⠤⠤⢤⡤⢤⡤⢤⡤⠤⢤ AAAAMMGGVVV
set build_revision 20260329300

# --- Colori e Stili ---
set colour_green (set_color 61bb46)
set colour_yellow (set_color f5d300)
set colour_orange (set_color f7941d)
set colour_red (set_color e21f26)
set colour_purple (set_color 973999)
set colour_blue (set_color 009cdc)
set style_bold (set_color --bold)
set style_italic (set_color --italics)
set style_reset (set_color normal)

# --- Percorsi e Configurazione ---
set install_path "$HOME/.config/rclone_script"
set log_filename (date +%F)"_log_rclone_"$build_revision".log"
set log_file_full_path "$install_path/$log_filename"
set filter_config "$install_path/config_files/rclone_script_upload.conf"
set git_update_url "https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh"
set script_path (status filename)

# --- Variabili Rclone ---
set lifespan "90d"
set log_level "INFO"

# --- Funzioni di Sistema ---

function cleanup --on-event fish_exit
    tput csr 0 (math (tput lines) - 1)
    if test $status -ne 0 -a $status -ne 143 # 143 è SIGTERM
        echo -e "\n$colour_red--- Errore Script: Output Log ---$style_reset"
        test -f "$log_file_full_path"; and cat "$log_file_full_path"
    end
end

function info
    echo -e "$colour_yellow==>$style_reset $style_italic$argv[1]$style_reset"
    printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) "INFO" "$argv[1]" >> "$log_file_full_path"
end

function warn
    echo -e "$colour_orangeAvviso:$style_reset $argv[1]"
    printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) "AVVISO" "$argv[1]" >> "$log_file_full_path"
end

function error
    echo -e "$colour_redErrore:$style_reset $argv[1]" >&2
    printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) "ERRORE" "$argv[1]" >> "$log_file_full_path"
    exit 1
end

function banner_function
    clear
    tput csr 9 (math (tput lines) - 1)
    tput cup 0 0
    printf '\033[?7l' # Disabilita line wrap
    echo -e "$colour_green               ⠘⣿⡇                                               ⠻⠃           ⣼$style_reset"
    echo -e "$colour_yellow    ⣿⣤⡿⠛⠃ ⣴⡿⠛⠻⠏ ⣿⡇  ⣶⠿⠛⠿⣶  ⢸⣷⡾⠛⠻⣿⡄  ⣰⡿⠛⠻⣷     ⢀⣾⠛⠛⠿⠃ ⢠⣾⠟⠛⠿ ⢸⣧⣾⠟⠛ ⣿⡇ ⢸⣷⡾⠛⠻⣷ ⠛⣿⠛⠛  ⢠⣾⠟⠛⠛⠿⣷$style_reset"
    echo -e "$colour_orange    ⣿⡏   ⢠⣿     ⣿⡇ ⣼⡏   ⢸⣷ ⢸⣿   ⢸⡇ ⢠⣿⣀⣀⣀⣹⡇    ⠘⣿⣄    ⣿⠁    ⢸⣿    ⣿⡇ ⢸⣿   ⠘⣿  ⣿       ⠶⠶⣄⡀$style_reset"
    echo -e "$colour_red    ⣿⡇   ⢸⣿     ⣿⡇ ⢿⡇   ⢸⣿ ⢸⣿   ⢸⡇ ⠸⣿⠉⠉⠉⠉⠁      ⠉⠛⣿⡄ ⣿     ⢸⣿    ⣿⡇ ⢸⣿   ⢀⣿  ⣿       ⠠⠶⠶⣄$style_reset"
    echo -e "$colour_purple    ⣿⡇    ⢿⣦⣀⣀⣀ ⣿⡇ ⠈⣿⣄⣀⣀⣿⠃ ⢸⣿   ⢸⡇  ⢿⣦⣀⣀⣀⡄    ⢠⣀ ⣀⣼⠇ ⠻⣷⣀⣀⣀ ⢸⣿    ⣿⡇ ⢸⣿⣄⣀⣀⣾⠏  ⣿⣄⢀ ⣠⣾⣄⣀⣀⣠⡾⠃$style_reset"
    echo -e "$colour_blue    ⠉⠁      ⠈⠉⠉⠁ ⠉⠁   ⠉⠉⠉   ⠈⠉   ⠈⠁   ⠈⠉⠉⠉      ⠉⠉⠉⠁    ⠉⠉⠉ ⠈⠉   ⠉⠁ ⢸⣿ ⠉⠉⠁    ⠉⠉ ⠻⠿⠿⠿⠿⠋$style_reset"
    echo -e "$colour_blue                                                                    ⢸⣿$style_reset"
    echo -e "$colour_blue                                                                     ⠉ $style_reset di Manuel Balbi - $style_bold v.$script_version$style_reset build $style_italic$build_revision$style_reset"
    printf '\033[?7h' # Riabilita line wrap
    tput cup 9 0
end

# --- Logica di Sincronizzazione ---

function esegui_rclone
    set modo $argv[1] # "bisync" o "resync"
    set rclone_remote $argv[2]
    set set_dryrun $argv[3]

    set cmd_type (rclone config show "$rclone_remote" | grep "^type =" | string split " " -f3)
    info "Esecuzione $modo su $rclone_remote ($cmd_type)..."

    set base_args --force --metadata --log-level "$log_level" --max-lock 2m --max-age "$lifespan" --filter-from "$filter_config"

    if test "$modo" = "resync"
        set -a base_args --resync --resync-mode newer
    else
        set -a base_args --resilient --recover --conflict-resolve newer
    end

    switch "$cmd_type"
        case "onedrive"
            rclone bisync "$HOME/" "$rclone_remote:/" $set_dryrun --onedrive-av-override --fast-list --onedrive-delta --compare modtime,size,checksum $base_args 2>&1 | tee -a "$log_file_full_path"
        case "drive"
            rclone bisync "$HOME/" "$rclone_remote:/" $set_dryrun --drive-skip-checksum-gphotos --drive-skip-gdocs --compare modtime,size,checksum $base_args 2>&1 | tee -a "$log_file_full_path"
        case "*"
            rclone bisync "$HOME/" "$rclone_remote:/" $set_dryrun --compare modtime,size $base_args 2>&1 | tee -a "$log_file_full_path"
    end
end

# --- Core dello Script ---

function main
    # Parsing degli argomenti con argparse
    set -l options 'n/no-dry-run' 'r/resync'
    argparse $options -- $argv
    or return 1

    banner_function

    # Update check
    info "Verifica aggiornamentio..."
    set remote_rev (curl -sL "$git_update_url" | grep "build_revision=" | head -1 | string replace -r '\D' '')
    if test -n "$remote_rev"; and test "$remote_rev" -gt "$build_revision"
        warn "Aggiornamento alla build $remote_rev in corso..."
        curl -sL "$git_update_url" -o "$script_path.tmp"; and mv "$script_path.tmp" "$script_path"
        chmod +x "$script_path"
        exec fish "$script_path" $argv
    end

    # Verifica configurazione
    if not test -f "$filter_config"; error "File filtri non trovato in $filter_config"; end
    set remotes (rclone listremotes | string replace -a ':' '')
    if test -z "$remotes"; error "Nessun rclon-remote configurato."; end

    # Impostazione flag dai parametri
    set dry_flag "--dry-run"
    if set -q _flag_no_dry_run
        set dry_flag ""
        info "Dry-run DISATTIVATO."
    end

    set modo "bisync"
    if set -q _flag_resync
        set modo "resync"
        info "Modalità RESYNC attivata."
    end

    # Ciclo sui remoti
    for remote in $remotes
        esegui_rclone "$modo" "$remote" "$dry_flag"
    end

    info "Operazione completata."

    # Controllo se chiudere la finestra (SID check alternativo per Fish)
    if test (ps -o ppid= -p %self | string trim) -eq 1
        echo -e "$colour_redÈ possibile chiudere la finestra.$style_reset"
        cat "$log_file_full_path"
    end

    cleanup

end

main $argv
