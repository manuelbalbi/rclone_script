# rclone_script
## Simple fish script to automate bisync on cloud services from Terminal

_rclone_script_ is a simple script written in *fish* that uses `rclone` previously configured remotes via `rclone config` via manual launch at the moment.<br>
Initial versions of _rclone_script_ where written in *bash*.
The goal is to make it a useful generic script _in the future_.

## Usage
_rclone_scipt_ parses some arguments:<br>
-h, --help        Show help message<br>
-d, --debug       Set DEBUG verbosity in rclone<br>
-r, --resync      Set resync on bisync in rclone<br>
-t, --time=VALUE  Set max life of files (e.g., -t 90d or --time=1y default is 90 years)<br>
-n, --no-dry-run  Run the script without dry-run safety<br>

## Features

- [X] Fish functions *rclone_script*
- [X] Auto update the script
- [X] Auto fetch remote list from rclone config
- [X] Guided configuration (*partial*) via `installer.fish`
- [ ] Avoid stop by idle/sleep/screen events

## Notes

> [!IMPORTANT]
> The rclone_script needs that at least one remote in configured in by using the `rclone config` via shell terminal

> [!WARNING]
> The rclone_script will fail if the lockscreen is activated (by idle time or by the user)
