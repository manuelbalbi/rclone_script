function rclone_script
    # --- Variabili di Versione ---
    set -g script_version "3.2.1"
    #                     ⡤⠤⠤⢤⡤⢤⡤⢤⡤⠤⢤ AAAAMMGGVVV
    set -g build_revision 20260530321

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
    set -g git_update_url "    https://raw.githubusercontent.com/manuelbalbi/rclone_script/refs/heads/main/rclone_script.fish
"
    set -g script_path (functions --details rclone_script)

    # --- Variabili di livello di servizio, set global value in v. 3.2.1
    set -g log_level --log-level INFO # set default log level INFO
    set -g lifespan --max-age 90y # set default lifespan = 90 years

    # --- Funzioni di Sistema ---

    function update_check # v. 3.2.0
        info "Verifica aggiornamento..."
        set -l remote_rev (curl -sL $git_update_url | string match -r -g 'build_revision\s+(\d+)') # v. 3.2.0
        if test -n "$remote_rev"; and test "$remote_rev" -gt "$build_revision"
            warn "Aggiornamento alla build $remote_rev in corso..."
            curl -sL $git_update_url -o "$script_path.tmp"; and mv "$script_path.tmp" $script_path
            exec fish "$script_path" $argv
            return 0
        end
    end

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
        printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) INFO "$argv[1]" >>"$log_file_full_path"
    end

    function warn
        echo -e "$colour_orangeAvviso:$style_reset $argv[1]"
        printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) AVVISO "$argv[1]" >>"$log_file_full_path"
    end

    function error
        echo -e "$colour_redErrore:$style_reset $argv[1]" >&2
        printf "%s %s %-6s: %s\n" (date +%Y-%m-%d) (date +%H:%M:%S) ERRORE "$argv[1]" >>"$log_file_full_path"
        return 1
    end

    function start_log # v. 3.2.0
        set -l stringa_apertura_chiusura "****************************************************************************************************" # header line
        set -l stringa_padding "*" # column line
        set -l larghezza_totale (string length "$stringa_apertura_chiusura")
        set -l larghezza_padding (math "2 * "(string length "$stringa_padding"))
        set -l larghezza_interna (math $larghezza_totale - $larghezza_padding)
        set -l testo_base "Avvio script v. $script_version build $build_revision."
        set -l stringa_centrata $stringa_padding(string pad -C -w $larghezza_interna "$testo_base")$stringa_padding
        info $stringa_apertura_chiusura
        info $stringa_centrata
        info $stringa_apertura_chiusura
    end

    function banner_function
        clear
        tput csr 9 (math (tput lines) - 1)
        tput cup 0 0
        printf '\033[?7l' # Disabilita line wrap
        figlet -cf script "rclone script 3" | lolcat
        set_color blue
        figlet -rf term "di Manuel Balbi - v. $script_version build $build_revision"
        set_color normal
        printf '\033[?7h' # Riabilita line wrap
        tput cup 9 0
    end

    # --- Logica di Sincronizzazione ---

    function esegui_rclone
        set -l modo $argv[1] # serivce "bisync" or "resync"
        set -l rclone_remote $argv[2] # remote serivce
        set -l dryrunonoff $argv[3] # dry-run parsing

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
            case drive
                set -a base_args --drive-skip-checksum-gphotos --drive-skip-gdocs --compare modtime,size,checksum
            case iclouddrive # v. 3.0.3 disable HTTP2 for iCloud Drive
                set -a base_args --disable-http2
            case '*' # v. 3.0.1 minor fix
                set -a base_args --compare modtime,size
        end

        # v. 3.0.3 razionalizazione script
        rclone bisync "$HOME/" "$rclone_remote:/" $base_args 2>&1 | tee -a $log_file_full_path
    end

    # --- Core dello Script ---
    # argparsing arguments, modified by v. 3.2.0
    argparse h/help n/no-dry-run r/resync 't/time=' d/debug -- $argv
    or return 1

    # argparse help value
    if set -ql _flag_help
        echo "Usage: rclone_script [OPTIONS]

Options:
-h, --help        Show this help message
-d, --debug       Set DEBUG verbosity in rclone
-r, --resync      Set resync on bisync in rclone
-t, --time=VALUE  Set max life of files (e.g., -t 90d or --time=1y default is 90 years)
-n, --no-dry-run  Run the script without dry-run safety"

        return 1
    end

    # argparse debug with --log-level attribute v. 3.2.0
    set -ql _flag_debug; and set log_level --log-level DEBUG

    # argparse lifespan with --max-age (default set by lifespan variable) - v. 3.2.0
    if set -ql _flag_time
        set lifespan $_flag_time[-1] # lifespan set by argparsing
    end

    banner_function
    start_log # v. 3.2.0

    update_check # v. 3.2.0

    # Verifica presenza file di configurazione
    if not test -f $filter_config
        error "File filtri non trovato in $filter_config"
    end

    # Verifica presenza almeno un servizio remoto nella configurazione di rclone
    set remotes (rclone listremotes | string replace -a ':' '')
    if not set -q remotes[1]
        error "Nessun rclone-remote configurato."
        return 1
    end

    # Impostazione flag dai parametri, in automatico imposta dry_args con il valore --dry-run
    set -l dry_args --dry-run
    set -q _flag_no_dry_run; and set dry_args; and info "Modalità dry-run disattivata."

    # Impostazione modo, in automatico imposta la modalità con funzione bisync
    set -l modo bisync
    set -q _flag_resync; and set modo resync; and info "Modalità RESYNC attivata."

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

    cat $log_file_full_path # v. 3.0.2 cat log file after cleanup

end
