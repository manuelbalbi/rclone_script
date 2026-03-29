# rclone_script
## Simple bash script to automate sync on cloud services from Terminal

_rclone_script_3_ is a simple script written in *fish* that uses rclone listed remotes previously configured via `rclone config` via manual launch at the moment.<br>
Initial versions of _rclone_script_ where written in *bash*.
The goal is to make it a useful generic script _in the future_.

## Features

- [X] Fish functions *rclone-script*
- [X] Auto update the script
- [X] Auto fetch remote list from rclone config
- [X] Guided configuration (*partial*)
- [ ] Avoid stop by idle/sleep/screen events

## Notes

> [!IMPORTANT]
> The rclone_script needs that at least one remote in configured in by using the `rclone config` via shell terminal

> [!WARNING]
> The rclone_script will fail if the lockscreen is activated (by time or by the user)
