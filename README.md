# rclone_script
## Simple bash script to automate sync on cloud services from Terminal

_rclone_script_ is a simple script written in *bash* that connect to rclone listed remotes previously configured via _rclone config_ via manual launch right now.<br>
It also copies some Steam screenshots to specific folders and moves "Screenshot" files to a specific folder within "Immagini".<br>
It's written for my needs right now, the goal is to make a useful generic script _in the future_.

From version *2.2* build _20260128_ the script serch the repository to auto update itself.<br>
From version *2.5* build _20260205_ the script search for rclone remotes to automatically use all of the listed remotes to sync/bisync/resync/copy data. The _download_ function sync only from the first entry in the remote list.<br>
Added _rclone-script_ user alias to launch the script.

## Features

- [X] User alias *rclone-script*
- [X] Auto update the script
- [X] Auto fetch remote list from rclone config
- [ ] Guided configuration
- [ ] No suspend trigger

## Notes

> [!IMPORTANT]
> The rclone_script needs that at least one remote in configured in rclone (rclone config via shell terminal)

> [!WARNING]
> The rclone_script will fail if the lockscreen is activated (by time or by the user)
