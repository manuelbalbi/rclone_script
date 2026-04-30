#!/usr/bin/fish

function rclone_script # è la "function main" per lo script salvato in .config/fish/functions/
    # --- Variabili di Versione ---
    set -g script_version "3.0.1"
    #                     ⡤⠤⠤⢤⡤⢤⡤⢤⡤⠤⢤ AAAAMMGGVVV
    set -g build_revision 20260429301

    # --- Colori e Stili ---
    set -g colour_green (set_color 61bb46)
    set -g colour_yellow (set_color f5d300)
    set -g colour_orange (set_color f7941d)
    set -g colour_red (set_color e21f26)
    set -g colour_purple (set_color 973999)
    set -g colour_blue (set_color 009cdc)
    set -g style_bold (set_color --bold)
    set -g style_italic (set_color --italics)
    set -g style_reset (set_color normal)

    # --- Percorsi e Configurazione ---
    set -g install_path "$HOME/.config/rclone_script"
    set -g log_filename (date +%F)"_log_rclone_"$build_revision".log"
    set -g log_file_full_path "$install_path/$log_filename"
    set -g filter_config "$install_path/config_files/rclone_script_upload.conf"
    set -g git_update_url "https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.sh"
    set -g script_path (functions --details rclone_script)

    # --- Variabili di livello di servizio
    set -g log_level --log-level INFO       # set log level between INFO and DEBUG
    set -g lifespan --max-age 90d           # lifespan set @ declared time, 90d = 90 days

    # --- Funzioni di Sistema ---
    function cleanup
        tput csr 0 (math (tput lines) - 1)
        if test $status -ne 0 -a $status -ne 143 # 143 è SIGTERM
            echo -e "\n$colour_red--- Errore Script: Output Log ---$style_reset"
            test -f "$log_file_full_path"; and cat "$log_file_full_path"
        end
        clear
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
        return 1
    end

    function banner_function
        clear
        tput csr 9 (math (tput lines) - 1)
        tput cup 0 0
        printf '\033[?7l' # Disabilita line wrap
        echo -e "$colour_green               ⠘⣿⡇                                               ⠻⠃          ⣼$style_reset"
        echo -e "$colour_yellow    ⣿⣤⡿⠛⠃ ⣴⡿⠛⠻⠏ ⣿⡇  ⣶⠿⠛⠿⣶  ⢸⣷⡾⠛⠻⣿⡄  ⣰⡿⠛⠻⣷     ⢀⣾⠛⠛⠿⠃ ⢠⣾⠟⠛⠿ ⢸⣧⣾⠟⠛ ⣿⡇ ⢸⣷⡾⠛⠻⣷  ⠛⣿⠛⠛  ⢠⣾⠟⠛⠛⠿⣷$style_reset"
        echo -e "$colour_orange    ⣿⡏   ⢠⣿     ⣿⡇ ⣼⡏   ⢸⣷ ⢸⣿   ⢸⡇ ⢠⣿⣀⣀⣀⣹⡇    ⠘⣿⣄    ⣿⠁    ⢸⣿    ⣿⡇ ⢸⣿   ⠘⣿  ⣿       ⠶⠶⣄⡀$style_reset"
        echo -e "$colour_red    ⣿⡇   ⢸⣿     ⣿⡇ ⢿⡇   ⢸⣿ ⢸⣿   ⢸⡇ ⠸⣿⠉⠉⠉⠉⠁      ⠉⠛⣿⡄ ⣿     ⢸⣿    ⣿⡇ ⢸⣿   ⢀⣿  ⣿       ⠠⠶⠶⣄$style_reset"
        echo -e "$colour_purple    ⣿⡇    ⢿⣦⣀⣀⣀ ⣿⡇ ⠈⣿⣄⣀⣀⣿⠃ ⢸⣿   ⢸⡇  ⢿⣦⣀⣀⣀⡄    ⢠⣀ ⣀⣼⠇ ⠻⣷⣀⣀⣀ ⢸⣿    ⣿⡇ ⢸⣿⣄⣀⣀⣾⠏  ⣿⣄⢀ ⣠⣾⣄⣀⣀⣠⡾⠃$style_reset"
        echo -e "$colour_blue    ⠉⠁     ⠈⠉⠉⠁ ⠉⠁   ⠉⠉⠉   ⠈⠉   ⠈⠁   ⠈⠉⠉⠉      ⠉⠉⠉⠁    ⠉⠉⠉ ⠈⠉    ⠉⠁ ⢸⣿ ⠉⠉⠁    ⠉⠉ ⠻⠿⠿⠿⠿⠋$style_reset"
        echo -e "$colour_blue                                                                    ⢸⣿$style_reset"
        echo -e "$colour_blue                                                                     ⠉ $style_reset di Manuel Balbi - $style_bold v.$script_version$style_reset build $style_italic$build_revision$style_reset"
        printf '\033[?7h' # Riabilita line wrap
        tput cup 9 0
    end

    # --- Logica di Sincronizzazione ---

    function esegui_rclone
        set -l modo $argv[1]            # serivce "bisync" or "resync"
        set -l rclone_remote $argv[2]   # remote serivce
        set -l dryrunonoff $argv[3]     # dry-run parsing

        set -l cmd_type (rclone config show $rclone_remote | grep "^type =" | string split " " -f3)
        info "Esecuzione $modo su $rclone_remote (tipo di servizio remoto $cmd_type)..."

        set -l base_args $dryrunonoff --contimeout 1m --low-level-retries 10 --force --metadata --filter-from $filter_config
        set -a base_args $log_level $lifespan

        switch $modo
            case resync
                set -a base_args --resync --resync-mode newer --max-lock 2m
            case bisync
                set -a base_args --resilient --recover --conflict-resolve newer --max-lock 2m
        end

        switch $cmd_type
            case onedrive
                set -a base_args --transfers 1 --onedrive-chunk-size 128000Ki --onedrive-av-override --fast-list --onedrive-delta --compare modtime,size,checksum
                rclone bisync "$HOME/" "$rclone_remote:/" $base_args 2>&1 | tee -a $log_file_full_path
            case drive
                set -a base_args --drive-skip-checksum-gphotos --drive-skip-gdocs --compare modtime,size,checksum
                rclone bisync "$HOME/" "$rclone_remote:/" $base_args 2>&1 | tee -a $log_file_full_path
            case '*' # v. 3.0.1 minor fix
                set -a base_args --compare modtime,size
                rclone bisync "$HOME/" "$rclone_remote:/" $base_args 2>&1 | tee -a $log_file_full_path
        end
    end

    # --- Core dello Script ---
    # Parsing degli argomenti con argparse
    set -l options 'n/no-dry-run' 'r/resync'
    argparse $options -- $argv
    or return 1

    banner_function
    info "Avvio script v.$script_version build $build_revision."

    # Update check
    info "Verifica aggiornamentio..."
    set remote_rev (curl -sL $git_update_url | grep "build_revision=" | head -1 | string replace -r '\D' '')
    if test -n "$remote_rev"; and test "$remote_rev" -gt "$build_revision"
        warn "Aggiornamento alla build $remote_rev in corso..."
        curl -sL $git_update_url -o "$script_path.tmp"; and mv "$script_path.tmp" $script_path
        exec fish "$script_path" $argv; return 0
    end

    # Verifica presenza file di configurazione
    if not test -f $filter_config; error "File filtri non trovato in $filter_config"; end

    # Verifica presenza almeno un servizio remoto nella configurazione di rclone
    set remotes (rclone listremotes | string replace -a ':' '')
    if not set -q remotes[1]
        error "Nessun rclone-remote configurato."
        return 1
    end

    # Impostazione flag dai parametri, in automatico imposta dry_args con il valore --dry-run
    set -l dry_args --dry-run
    set -q _flag_no_dry_run; and set dry_args; and info "Modalità dry-run disattivata."
    # if set -q _flag_no_dry_run
    #     set dry_args # Svuota la variabile
    #     info "Dry-run DISATTIVATO."
    # else
    #     set dry_args --dry-run
    #     info "Dry-run ATTIVATO."
    # end

    # Impostazione modo, in automatico imposta la modalità con funzione bisync
    set -l modo bisync
    set -q _flag_resync; and set modo resync; and info "Modalità RESYNC attivata."
    # if set -q _flag_resync
    #     set modo resync
    #     info "Modalità bisync con RESYNC attivata."
    # else
    #     set modo bisync
    #     info "Modalità bisync."
    # end

    # Ciclo sui remoti
    for remote in $remotes
        esegui_rclone $modo $remote $dry_args
    end

    info "Operazione completata."

    # Controllo se chiudere la finestra (SID check alternativo per Fish)
    if test (ps -o ppid= -p %self | string trim) -eq 1
        echo -e "$colour_redÈ possibile chiudere la finestra.$style_reset"
        cat $log_file_full_path
    end

    cleanup

end
