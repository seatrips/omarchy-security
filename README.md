# Omarchy Security Guide

How to make an [Omarchy](https://omarchy.org) laptop safe enough for private and work use, and keep it that way.
It covers what was checked, what was changed and why, and an automatic security scan that runs after every update.

It works on any Omarchy install (Arch Linux + Hyprland), on any hardware.
Nothing here depends on a specific laptop.

> **Safety first, convenience second.** Every change below was made only after checking what it breaks.
> Everything can be undone (see [Undo](#undo)).

## The layers

| # | Layer | What it protects against | Guide |
|---|---|---|---|
| 0 | Baseline audit | Knowing where you stand: disk encryption, open ports, sudo, ssh | [docs/01-baseline-audit.md](docs/01-baseline-audit.md) |
| 1 | Bluetooth pairing asks first | Strangers nearby pairing a device without asking | [docs/02-bluetooth.md](docs/02-bluetooth.md) |
| 2 | Firewalls: ufw (incoming) + OpenSnitch (outgoing, per program) | Network attacks; programs sending data without you knowing | [docs/03-opensnitch.md](docs/03-opensnitch.md) |
| 3 | Security Watch: daily scans | Vulnerable packages, rootkits, tampered system files, weak settings | [docs/04-security-watch.md](docs/04-security-watch.md) |
| 4 | **Scan after every update** | New services, open ports, broken configs or failed units that an update brings in | [docs/05-after-update-scan.md](docs/05-after-update-scan.md) |
| 5 | Kernel hardening | Common exploit aids (kernel address leaks, FIFO/file tricks, setuid core dumps) | [docs/06-kernel-hardening.md](docs/06-kernel-hardening.md) |
| 6 | Unused network protocols blocked | Kernel bugs in protocols a laptop never uses (DCCP, SCTP, RDS, TIPC) | [docs/07-blocked-protocols.md](docs/07-blocked-protocols.md) |
| — | When you get a notification | What each alert means and what to do | [docs/08-triage.md](docs/08-triage.md) |
| — | Habits | Updates, apps, secrets, git | [docs/09-habits.md](docs/09-habits.md) |

The idea: **quiet unless action is needed.** You get a desktop notification only for a *new* finding, plus a short "all clear" after each update.

## Quick start

```bash
git clone <this repo> ~/omarchy-security
cd ~/omarchy-security
less install.sh        # read it first: it uses sudo
./install.sh           # installs every layer, backs up any file it replaces
sudo systemctl start security-watch   # first scan now
./check.sh             # read-only status of every layer
```

`install.sh` is safe to run again. You can also do every step by hand: each doc shows the exact commands.

## What's in the repo

```
install.sh        installs all layers (backs up replaced files to *.bak.<timestamp>)
uninstall.sh      removes them again
check.sh          read-only: is every layer on, and did the last update leave problems?
files/            the exact files that get installed, at their system paths
  usr/local/bin/security-watch          the scanner
  usr/local/bin/blocked-module          refuses + reports blocked protocols
  etc/systemd/system/security-watch.*   daily timer
  etc/pacman.d/hooks/*.hook             post-update scan + rkhunter baseline refresh
  etc/sysctl.d/99-zz-hardening.conf     kernel hardening
  etc/modprobe.d/blocked-protocols.conf protocol block
  etc/rkhunter.conf.local               known false positives
  etc/lynis/custom.prf                  lynis profile
  etc/opensnitchd/rules/*.json          3 base allow rules (local DNS, resolver, clock)
docs/             the guide, one page per layer
```

## Daily use

- **Notification "Post-update scan: all clear"** after an update: nothing to do.
- **Any other Security Watch notification:** read `sudo tail -40 /var/log/security-watch.log`, then [docs/08-triage.md](docs/08-triage.md).
- **OpenSnitch popup:** a program wants to go online. Allow it only if you know the program and why it needs the network.
- **After you update**, run `./check.sh` too if you want to see the full picture yourself.

## Undo

`./uninstall.sh` removes the scanner, the hooks, the kernel settings and the protocol block, and turns OpenSnitch off.
Bluetooth auto-accept stays off unless you turn it back on (the script prints how). Reboot afterwards.
Each doc also has an **Undo** section for its own layer.

## What this does *not* do

- It is no replacement for updates. Update often (`omarchy update`); Security Watch tells you when a security fix is waiting.
- It doesn't turn on Secure Boot or turn off autologin. Omarchy logs you in automatically after the disk password, so **the LUKS disk password is your login.** Pick a strong one.
- It doesn't send anything anywhere. All scans run locally; results stay in `/var/log/security-watch.log`.
