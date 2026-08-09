# Devuan migration — backup + reinstall scripts

Backup of the current Devuan Excalibur (trixie, runit) system plus idempotent
reinstall scripts. Targets a fresh netinstall minimal of Devuan 6.0 Excalibur.

State at generation time: shellcheck clean (`shellcheck -x *.sh` exit 0),
syntax clean (`sh -n` POSIX / `bash -n` for the orchestrator).

---

## Quick start — fresh install checklist (TL;DR)

If you just installed Devuan minimal and want to use this repo, follow these
exact steps. Detailed explanations live further down.

### Option A — clone from GitHub (recommended, needs internet)

Logged in as **root** on the new system:

```sh
apt update && apt install -y git git-lfs ca-certificates
git lfs install
git clone https://github.com/ezequielgk/Dotfiles-Backup.git /home/ezequiel/devuan-migration
chown -R ezequiel:ezequiel /home/ezequiel/devuan-migration
bash /home/ezequiel/devuan-migration/scripts/00-base.sh
bash /home/ezequiel/devuan-migration/scripts/01-devuan-depot.sh
exit   # salir de root
```

Then log in as **ezequiel** (your normal user, created during the netinstall)
and run:

```sh
bash ~/devuan-migration/scripts/install-all.sh
```

The orchestrator runs scripts `02 → 03b → 03 → 04b → 05 → 05b → 06 → 07 →
08 → 08b → 10` in order, pausing before each for `[s] correr / [r] reintentar
/ [a] abortar`. All output goes to `~/devuan-migration/install.log`. On any
failure it stops there.

After it finishes (it auto-runs `restore-from-backup.sh` for you), run these
**three manual steps** the scripts cannot do for you:

```sh
# 1. Activate your real home-manager flake (overwrites the 03b scaffold)
nix run home-manager/master -- switch --flake ~/.config/home-manager#ezequiel --impure

# 2. Restart emptty so it picks the restored /etc/emptty/conf-tty7
sudo sv restart emptty

# 3. Fully log out and back in for the PAM gnome-keyring hook to activate
```

Verify:

```sh
sv status /etc/runit/runsvdir/default/*   # emptty, dbus, elogind, zramswap should be active
swapon --show                              # /dev/zram0 prio 100 ~8G + /swapfile prio 10 8G
pactl info                                 # audio: should show Default Sample Rate, not "Connection failed"
```

### Option B — restore from local tarball (offline, no internet required)

If you also generated a local `devuan-backup.tar.zst` (Phase 1 last step),
copy it to a USB before reinstalling, then on the new system:

```sh
# as root
apt install -y zstd
tar --zstd -xf /media/usb/devuan-backup.tar.zst -C /home/ezequiel
chown -R ezequiel:ezequiel /home/ezequiel/devuan-migration
bash /home/ezequiel/devuan-migration/scripts/00-base.sh
bash /home/ezequiel/devuan-migration/scripts/01-devuan-depot.sh
exit
```

Log in as **ezequiel**, then `bash ~/devuan-migration/scripts/install-all.sh`,
then the three manual steps above.

### Heads-up: what the repo on GitHub looks like

The repo `Dotfiles-Backup` on GitHub has two branches:
- `main` — this `devuan-migration/` tree (scripts, backup, README)
- `legacy` — the previous Dotfiles-Backup contents (only relevant if you ever
  want to go back to the old dotfiles-only backup; ignore for fresh installs)

The `backup/appearance/fonts/` directory contains 161 `.ttf` files tracked via
**Git LFS** (NotoSerifCJK are ~58 MB each, ~286 MB total). `git lfs install`
before clone is mandatory — otherwise you get pointer files instead of real
fonts.

---

## Tree

```
~/devuan-migration/
├── backup/                       # Phase 1 — git repo, 9 categories
│   ├── MANIFEST.md               # Source -> dest + sizes per category
│   ├── wm/{sway,mango}/
│   ├── terminal/foot/
│   ├── shell/fish/
│   ├── noctalia/{config,state}/
│   ├── portal/xdg-desktop-portal/
│   ├── home-manager/             # flake.nix, flake.lock, home.nix
│   ├── appearance/{themes,icons,fonts}/
│   ├── emptty/etc/emptty/{conf-tty7,motd}      # root:root literal
│   └── pam/etc/pam.d/emptty                     # root:root literal
├── scripts/
│   ├── 00-base.sh                # root
│   ├── 01-devuan-depot.sh        # root
│   ├── 02-sudo-doas.sh           # user+sudo
│   ├── 03b-nix-homemanager.sh    # user, no sudo (Nix installer refuses root)
│   ├── 03-fish-strawberry.sh
│   ├── 04b-audio.sh
│   ├── 05-pcmanfmqt-foot.sh
│   ├── 05b-qt6ct.sh
│   ├── 06-emptty.sh
│   ├── 07-mango-noctalia-dotfiles.sh
│   ├── 08-keyring.sh
│   ├── 08b-polkit.sh
│   ├── 10-zram-swap.sh
│   ├── restore-from-backup.sh
│   └── install-all.sh            # bash (needs pipefail) — the orchestrator
└── install.log                   # written by install-all.sh on the new system
```

Phase-1 helpers (not used post-install): `precheck.sh`, `backup-nosudo.sh`,
`sudo-backup.sh`, `commit-sudo.sh`, `manifest.sh`.

---

## Phase 1 — on the CURRENT system (before reinstalling)

Already done in this session. To redo from scratch:

```sh
bash ~/devuan-migration/scripts/precheck.sh          # list + sizes, no copy
bash ~/devuan-migration/scripts/backup-nosudo.sh    # 7 user categories + git commits
sudo bash ~/devuan-migration/scripts/sudo-backup.sh # emptty + pam, root:root preserved
sudo bash ~/devuan-migration/scripts/commit-sudo.sh # git commit for the above
bash ~/devuan-migration/scripts/manifest.sh         # regen MANIFEST.md
```

Last step before wiping the disk: compress the whole `devuan-migration/` tree
(backup + scripts + this README + install.log) and move it off the disk you
are about to repartition:

```sh
tar --zstd -cf /media/external/devuan-backup.tar.zst -C "$HOME" devuan-migration/
```

`backup/` is intentionally uncompressed and browsable while you review it.
Compression is your manual call, not script-driven.

---

## Phase 2 — on the NEWLY installed system

### Pre-conditions

- Fresh Devuan 6.0 Excalibur netinstall, tasksel empty, init = runit.
- Kernel command line as you want it (system uses grub — Limine is out).
- `devuan-backup.tar.zst` reachable from the new system (USB, network, etc.).
- You are logged in as the future regular user (named `ezequiel` here — adjust
  the home-manager switch command below if your username differs).

### Step 1 — restore the tarball

```sh
tar --zstd -xf /path/to/devuan-backup.tar.zst -C "$HOME"
```

This puts `~/devuan-migration/` back, with `backup/`, `scripts/`, and this
`README.md`. The backup git repo is included — but note **the embedded plugin
repos under `noctalia/state/.../plugins/sources/*/repo` are gitlinks** (see
`Known gotchas`). The tar still contains the actual files, so restore via tar
(not via `git clone` of the backup repo).

### Step 2 — base + Devuan-Depot (as root)

`sudo` is not installed yet at this stage. Run these as root (`su -` or login
as root on the new system):

```sh
bash ~/devuan-migration/scripts/00-base.sh
bash ~/devuan-migration/scripts/01-devuan-depot.sh
```

`00-base.sh` installs firmware, build tools, locales (`es_AR.UTF-8`), seatd.
`01-devuan-depot.sh` imports the GPG key of your personal APT repo and writes
`/etc/apt/sources.list.d/devuan-depot.list` so `foot` and `mangowc` can resolve.

### Step 3 — everything else (as your user)

Log out of root, log in as your user. Then:

```sh
bash ~/devuan-migration/scripts/install-all.sh
```

The orchestrator runs the install scripts in order, **pausing before each**
for `[s] correr / [r] reintentar / [a] abortar`. Everything is appended to
`~/devuan-migration/install.log` with timestamps. If any script exits nonzero,
the orchestrator stops there — it does NOT continue to the next.

### Step 4 — automatic restore

When `install-all.sh` finishes successfully, it calls
`restore-from-backup.sh` for you. That script:

1. Reads `backup/MANIFEST.md`.
2. For each category, checks that the prerequisite install script has run
   (via `dpkg -s <pkg>` / `command -v nix`).
3. Prompts `[s/n/a]` per category; refuses to overwrite an existing dest
   without an explicit `s`.
4. `cp -a` for user categories, `sudo cp -a` for `emptty` and `pam` (preserves
   literal `root:root` mode).

### Step 5 — manual steps the scripts will NOT run for you

These are the items that the orchestrator prints at the end. Run them in this
order:

1. **Activate your real home-manager flake** (the 03b `init` only bootstraps a
   scaffold; the restore overwrote it with your flake from the backup):

   ```sh
   nix run home-manager/master -- switch --flake ~/.config/home-manager#ezequiel --impure
   ```

   `--impure` is required because `home.nix` uses `builtins.fetchTarball` for
   nixGL. Adjust `#ezequiel` to your `homeConfigurations."$USER"` attribute
   name if different.

2. **Restart emptty** so it picks up the restored `/etc/emptty/conf-tty7`:

   ```sh
   sudo sv restart emptty
   ```

3. **Re-login** for the PAM hook of gnome-keyring to activate auto-unlock
   (without re-login, the keyring asks for its password the first time instead
   of unlocking with your login password).

4. **Verify services**:

   ```sh
   sv status /etc/runit/runsvdir/default/*
   # Expected: emptty, dbus, elogind, zramswap active (+ getty-ttyN, etc.)
   ```

5. **Verify swaps**:

   ```sh
   swapon --show
   # Expected: /dev/zram0 prio 100 ~8G, /swapfile prio 10 8G
   ```

---

## Install order (canonical)

`install-all.sh` runs exactly this sequence, in order:

| # | Script | Action |
|---|---|---|
| 00 | `00-base.sh` | root. apt upgrade, firmware, build tools, `es_AR.UTF-8`, seatd |
| 01 | `01-devuan-depot.sh` | root. GPG key + `sources.list.d/devuan-depot.list` |
| 02 | `02-sudo-doas.sh` | `sudo` + `doas`, `/etc/doas.conf` (`permit persist $USER as root`, 0400), user added to `sudo` group |
| 03b | `03b-nix-homemanager.sh` | Nix single-user (no daemon), flakes enabled, channels `home-manager` + `nixpkgs`, `home-manager init` (no `switch`) |
| 03 | `03-fish-strawberry.sh` | `fish` + `strawberry`, `chsh -s /usr/bin/fish $USER` |
| 04b | `04b-audio.sh` | `pipewire` + `pipewire-audio` + `wireplumber` + `pipewire-pulse` + `pipewire-alsa` (D-Bus may auto-start; autostart.sh of Mango also spawns them) |
| 05 | `05-pcmanfmqt-foot.sh` | `pcmanfm-qt` (Debian) + `foot` (Devuan-Depot) |
| 05b | `05b-qt6ct.sh` | `qt6ct` (env vars already in restored `~/.config/mango/autostart.sh`) |
| 06 | `06-emptty.sh` | `emptty` + hand-built runit service `/etc/sv/emptty/` (foreground, svlogd logging) + symlink to `runsvdir/default/` |
| 07 | `07-mango-noctalia-dotfiles.sh` | `mangowc` (Devuan-Depot) + Noctalia APT repo (keyring + sources) + `noctalia` |
| 08 | `08-keyring.sh` | `gnome-keyring` + `libpam-gnome-keyring` (PAM hook restored separately) |
| 08b | `08b-polkit.sh` | `policykit-1` + `elogind` + `libpam-elogind` + `dbus`. Detects `/etc/sv/` vs `/usr/share/runit/sv.current/` and symlinks into `runsvdir/default/`; if missing, builds the service dir by hand |
| 10 | `10-zram-swap.sh` | `zram-tools` with 50% / zstd / prio 100, `/swapfile` 8G prio 10 in fstab, `vm.swappiness=150` |

`09-limine.sh` was dropped the plan — the system uses grub; no Limine
infrastructure is installed or backed up.

After those run, `install-all.sh` calls `restore-from-backup.sh`.

---

## Restore dependency matrix

`restore-from-backup.sh` enforces these gates per category. If a gate is not
met, the category is skipped with a hint rather than failing the restore.

| Category | Restore destination | Requires install scripts (already run) | Copy mode |
|---|---|---|---|
| `wm` | `~/.config/sway`, `~/.config/mango` | `07` (mangowc), `03` (fish) | `cp -a` |
| `terminal` | `~/.config/foot` | (none) | `cp -a` |
| `shell` | `~/.config/fish` | `03` (fish) | `cp -a` |
| `noctalia` | `~/.config/noctalia`, `~/.local/state/noctalia` | `07` (noctalia) | `cp -a` |
| `portal` | `~/.config/xdg-desktop-portal` | (none) | `cp -a` |
| `home-manager` | `~/.config/home-manager` | `03b` (nix + `home-manager init`) | `cp -a` (overwrites the scaffold) |
| `appearance` | `~/.local/share/{themes,icons,fonts}` | (none) | `cp -a` |
| `emptty` | `/etc/emptty/{conf-tty7,motd}` | `06` (emptty) | `sudo cp -a`, literal `root:root` |
| `pam` | `/etc/pam.d/emptty` | `08` (libpam-gnome-keyring) | `sudo cp -a`, literal `root:root` |

---

## Known gotchas

### 1. Noctalia plugin repos embedded in the backup (`gitlinks`)

`backup/noctalia/state/noctalia/plugins/sources/{community,official}/repo`
contain their own `.git` directories (they are plugin source clones). The
outer backup git repo treats them as gitlinks. **For the tar-restore flow
this does NOT matter** — `tar` copies the on-disk files, the gitlinks are
irrelevant. It would only bite you if you tried to `git clone` the backup
repo itself instead of restoring from tar — those two dirs would be empty
after a clone. Stick with `tar --zstd -xf` and you are fine.

### 2. `install-all.sh` is bash, the rest are POSIX sh

Only the orchestrator needs `pipefail` (POSIX sh does not have it). The
shebang is `#!/usr/bin/env bash` and the inline comment explains why.

### 3. `chsh` to fish does not affect the current session

`03-fish-strawberry.sh` runs `chsh -s /usr/bin/fish $USER`. The shell you are
running `install-all.sh` from is NOT changed mid-script. Log out and back in
to actually be in fish.

### 4. PAM hook restore happens AFTER the emptty PAM file is installed

When the `emptty` package installs, it ships a default `/etc/pam.d/emptty`
without the gnome-keyring hook. The `pam` category restore overwrites it with
your real version (which has `auth optional pam_gnome_keyring.so` and
`session optional pam_gnome_keyring.so auto_start`). If emptty is reinstalled
or upgraded later, that file may be clobbered — re-run the `pam` part of the
restore if that happens.

### 5. `conf-tty7` mode 0640 vs git's 100644 normalization

Git's tree objects store only two regular-file modes: `100644` (non-exec) or
`100755` (exec). Anything else (like 0640) is normalized at index time. So
`backup/emptty/etc/emptty/conf-tty7` (originally `root:root 0640`) ends up as
`100644` in the git tree. After a fresh `git clone`, the file on disk has mode
`0644`, not `0640`. The working-tree file in the `Dotfiles-Backup` checkout is
chmod'd 0640 explicitly (preserved by `tar`), but the moment anyone clones
the repo, that resets to 0644.

`restore-from-backup.sh` handles this by `sudo chmod 0640 /etc/emptty/conf-tty7`
right after the copy, regardless of the mode the backup file has on disk. Safe.

### 5. Nix single-user (no daemon)

Your current system runs Nix in single-user mode (verified: no `nix-daemon`
process, no `nixbld*` users, store at `/nix/store` owned by your user).
`03b-nix-homemanager.sh` installs the same way: `sh <(curl ... ) --no-confirm`
without `--daemon`. No runit service needed for nix.

### 6. `/etc/xdg-desktop-portal` is not backed up

It does not exist on the current system. The portal category covers only
`~/.config/xdg-desktop-portal`. If you set up `/etc/xdg-desktop-portal` later
on the new system, it is a fresh config (intentional).

### 7. shellcheck directives in the scripts

`manifest.sh` carries `# shellcheck disable=SC2016,SC2129` at the top. Those
warnings are false positives: `printf` does not expand shell backticks even
inside single-quoted format strings, and the per-line redirect style is
intentional for the table builder. `00-base.sh` has two `# shellcheck disable=
SC2086` directives on `apt install $PACKAGES` — the word split is intentional
because `PACKAGES` is a space-separated string, not a single package.

---

## Recap of commands per phase

```sh
# Phase 1 (current system, already done):
bash ~/devuan-migration/scripts/precheck.sh
bash ~/devuan-migration/scripts/backup-nosudo.sh
sudo bash ~/devuan-migration/scripts/sudo-backup.sh
sudo bash ~/devuan-migration/scripts/commit-sudo.sh
bash ~/devuan-migration/scripts/manifest.sh
tar --zstd -cf /media/external/devuan-backup.tar.zst -C "$HOME" devuan-migration/

# Phase 2 (new system):
tar --zstd -xf /media/external/devuan-backup.tar.zst -C "$HOME"
# as root:
bash ~/devuan-migration/scripts/00-base.sh
bash ~/devuan-migration/scripts/01-devuan-depot.sh
# as user:
bash ~/devuan-migration/scripts/install-all.sh
# after install-all.sh + auto-restore finish:
nix run home-manager/master -- switch --flake ~/.config/home-manager#ezequiel --impure
sudo sv restart emptty
# re-login for PAM gnome-keyring
sv status /etc/runit/runsvdir/default/*
swapon --show
```