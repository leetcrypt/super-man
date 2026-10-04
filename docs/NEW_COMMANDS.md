# super-man — Command Coverage Tracker

Tracks the flag-audit fixes and the new entries being added to `commands-db.json`.

## Flag-audit fixes (DONE)

- [x] `search-in-files` — document `--include` (used in example, was unexplained)
- [x] `list-processes` — document `f` (forest) and `--sort` (used in examples)

> Audit result: 75/77 entries already explained every flag they used. Only the two above had example-flags missing from `flags_explained`.

## New entries — ADDED (49 entries, DB now 126 tasks)

All entries below were added to `commands-db.json`, the `categories` index was kept in
sync, JSON validated, integrity-checked, and verified searchable via `super-man ask`.


IDs are kebab-case to match existing style. Each entry needs: `id`, `keywords`, `category`,
`command`, `description`, `examples[]`, `related[]`, `flags_explained{}`.

### text
- [x] `tail-follow` — `tail -f` (follow logs)
- [x] `head-tail` — `head` / `tail` first & last N lines
- [x] `cut-columns` — `cut -d -f` (delimiter columns)
- [x] `pipe-xargs` — `xargs` (build args from stdin)
- [x] `tee-output` — `tee` (write stdout to file + screen)
- [x] `tabulate-columns` — `column -t` (align into columns)

### files
- [x] `touch-file` — `touch` (create/update timestamps)
- [x] `file-info` — `stat` (size, perms, timestamps)
- [x] `file-type` — `file` (detect file type)
- [x] `directory-tree` — `tree`
- [x] `path-parts` — `basename` / `dirname`
- [x] `zip-folder` — `zip`
- [x] `unzip-archive` — `unzip`
- [x] `list-block-devices` — `lsblk`
- [x] `mount-filesystem` — `mount` / `umount`

### system
- [x] `kill-by-name` — `pkill` / `pgrep` / `killall`
- [x] `interactive-monitor` — `htop`
- [x] `system-info` — `uname -a`
- [x] `locate-command` — `which` / `whereis` / `type`
- [x] `command-history` — `history`
- [x] `background-jobs` — `jobs` / `bg` / `fg` / `nohup`
- [x] `run-with-timeout` — `timeout`
- [x] `format-date` — `date`
- [x] `count-cpus` — `nproc`

### network
- [x] `ssh-connect` — `ssh`
- [x] `ssh-key-setup` — `ssh-keygen` / `ssh-copy-id`
- [x] `show-ip-address` — `ip addr` / `ip route`
- [x] `trace-route` — `traceroute` / `mtr`
- [x] `netcat` — `nc`
- [x] `port-scan` — `nmap`
- [x] `http-request` — `curl` POST / download

### packages
- [x] `install-cross-platform` — `apt` / `dnf` / `pacman` / `brew`
- [x] `dpkg-query` — `dpkg`
- [x] `snap-flatpak` — `snap` / `flatpak`

### git
- [x] `git-rebase`
- [x] `git-cherry-pick`
- [x] `git-tag`
- [x] `git-remote`
- [x] `git-fetch`
- [x] `git-blame`

### docker
- [x] `docker-build`
- [x] `docker-pull`
- [x] `docker-remove` — `docker rm` / `rmi`
- [x] `docker-compose`
- [x] `docker-prune`
- [x] `docker-inspect`

### users
- [x] `show-user-id` — `id` / `groups`
- [x] `switch-user` — `su` / `sudo`
- [x] `login-history` — `last` / `lastlog`
