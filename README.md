# rclone_script
## Simple bash script to automate sync on cloud services from Terminal

_rclone_script_ is a simple script written in *bash* that uses rclone listed remotes previously configured via `rclone config` via manual launch at the moment.<br>
It also copies some Steam screenshots to specific folders and moves "Screenshot" files to a specific folder within "Immagini".<br>
It's written for my needs right now, the goal is to make it a useful generic script _in the future_.

Starting from version *2.2* build _20260128_ the script search the github repository to auto update itself.<br>
Starting from version *2.5* build _20260205_ the script search for rclone remotes to automatically use all of the listed remotes to sync/bisync/resync/copy data. The _download_ function sync only from the first entry in the remote list.<br>
Starting form version *2.6* build _20260304_ the script checks for dedicated `rclone commands` specific to the relative remote service in use.<br> 

## Features

- [X] User alias *rclone-script*
- [X] Auto update the script
- [X] Auto fetch remote list from rclone config
- [ ] Guided configuration
- [ ] Avoid stop by idle/sleep/screen events

## Notes

> [!IMPORTANT]
> The rclone_script needs that at least one remote in configured in by using the `rclone config` via shell terminal

> [!WARNING]
> The rclone_script will fail if the lockscreen is activated (by time or by the user)
