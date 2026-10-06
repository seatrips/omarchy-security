# Omarchy Security Guide

What you can add to an [Omarchy](https://omarchy.org) laptop to make it as safe as possible for private and work use, and why.
It covers what we checked, what we added and why, and a security scan that runs after every update.

**This is an awareness guide, not an installer.** It shows *what* is worth adding and *why*, so you can
decide what fits you. *How* to install it depends on your hardware and Omarchy version, and we can't test
every combination. Use the commands and example files here as a reference: do it by hand, or let your
AI assistant (Claude, or any other) adapt them to your system. See [How to use this guide](#how-to-use-this-guide).

Nothing here depends on a specific laptop.

> **Safety first, convenience second.** Every change below was made only after checking what it breaks.
> Everything can be undone (see [Undo](#undo)).

## Why this guide exists

**Not because Omarchy is unsafe.** Omarchy starts from a good place: full-disk encryption, a firewall that
drops incoming traffic, no SSH server, signed packages and fast security updates from Arch. For most people
that's already more secure than a typical laptop.

We use our laptop for private life *and* work: online banking, email, work files. For that we wanted it
**as safe as reasonably possible**, not just "safe by default". So we asked a few questions that no default
install can answer for you:

- **Who is my laptop talking to?** ufw guards the door coming in, but any program can still go out.
  OpenSnitch shows you every program that goes online and lets you decide.
- **Would I notice if something changed?** A secure system on day one can drift: an update enables a
  service, opens a port, ships a new config, or brings back a setting you turned off. Security Watch checks
  every day and **after every update**, and tells you only when something new needs your attention.
- **Can the defaults be a bit tighter without breaking anything?** Omarchy is a desktop for everyone, so it
  makes convenient choices, like accepting Bluetooth pairing without asking. We tightened only things that don't change
  how you use the laptop: Bluetooth asks first, a few kernel settings make exploits harder, and unused network
  protocols are off.
- **Would I know what to do?** Every alert has a plain explanation and a fix in [docs/08-triage.md](docs/08-triage.md).

The rules we followed:

1. **Check before changing.** Audit first, then change only what has a clear reason.
2. **Nothing may break silently.** Where a change could block something (OpenSnitch, the protocol block),
   you get a notification that says what happened and how to undo it.
3. **Quiet unless action is needed.** No daily noise: an alert means "look at this".
4. **Everything can be undone.** Every page ends with an Undo section.
5. **Nothing leaves the laptop.** All scans run locally.

Security is layers: no single tool here is perfect, but together they make problems much more likely to be
stopped or noticed early. This repo shares what we learned so other Omarchy users know what's possible and can choose for themselves.

## The layers

| # | Layer | What it protects against | Guide |
|---|---|---|---|
| 0 | Baseline audit + ufw firewall for incoming traffic | Knowing where you stand: disk encryption, open ports, sudo, ssh | [docs/01-baseline-audit.md](docs/01-baseline-audit.md) |
| 1 | Bluetooth pairing asks first | Strangers nearby pairing a device without asking | [docs/02-bluetooth.md](docs/02-bluetooth.md) |
| 2 | Security Watch: daily scans | Vulnerable packages, rootkits, tampered system files, weak settings | [docs/03-security-watch.md](docs/03-security-watch.md) |
| 3 | **Scan after every update** | New services, open ports, broken configs or failed units that an update brings in | [docs/04-after-update-scan.md](docs/04-after-update-scan.md) |
| 4 | Kernel hardening | Common exploit aids (kernel address leaks, FIFO/file tricks, setuid core dumps) | [docs/05-kernel-hardening.md](docs/05-kernel-hardening.md) |
| 5 | Unused network protocols blocked | Kernel bugs in protocols a laptop never uses (DCCP, SCTP, RDS, TIPC) | [docs/06-blocked-protocols.md](docs/06-blocked-protocols.md) |
| 6 | **OpenSnitch: install it LAST** | Programs sending data without you knowing (outgoing firewall, per program) | [docs/07-opensnitch-last.md](docs/07-opensnitch-last.md) |
| — | When you get a notification | What each alert means and what to do | [docs/08-triage.md](docs/08-triage.md) |
| — | Habits | Updates, apps, secrets, git | [docs/09-habits.md](docs/09-habits.md) |

The idea: **quiet unless action is needed.** You get a desktop notification only for a *new* finding, plus a short "all clear" after each update.

## How to use this guide

1. **Read** the "Why" above and the [layers](#the-layers). Each doc page explains the risk, the fix and its trade-offs.
2. **Decide** which layers you want. They are independent; take one, some or all.
   Things you rely on (printing, Docker, a VPN, a USB WiFi adapter) may change your choices: each page says what a layer could affect.
3. **Apply it your way:**
   - **By hand:** every doc page shows the commands and has an **Undo** section.
   - **With an AI assistant:** point it at this repo and let it check your system first. For example:
     > *Read https://github.com/seatrips/omarchy-security. Check my Omarchy system against each layer and tell me
     > what's already in place and what's missing. Then explain what each missing layer would change on my machine
     > before you change anything. Do OpenSnitch last.*
   - **Scripts as reference:** `install.sh`, `uninstall.sh` and `files/` are what we ran on our own machine.
     Read them before running anything; on a different Omarchy version or hardware, paths and defaults can differ.
4. **Verify:** `./check.sh` is read-only and safe to run anywhere. It shows which layers are on and what changed since your last update.

> [!IMPORTANT]
> **Whatever way you choose: install OpenSnitch last, and stay at the screen when you do.** It shows a popup for
> every program that goes online for the first time. A popup you miss for 30 seconds becomes a **deny rule for 12 hours**,
> and that program looks broken with no clue why. Set up everything else first, then OpenSnitch, then answer the popups
> (arch-audit first, so the security scan can check for updates).

> [!NOTE]
> **Tested on:** our own machines with Omarchy 4.0.x (October 2026). Not tested on other hardware or versions.
> The *ideas* apply to every Omarchy install; check the details before you apply them.

## What's in the repo

```
docs/             the guide: one page per layer (start here)
check.sh          read-only: is every layer on, and did the last update leave problems?
files/            reference copies of the files we installed, at their system paths
  usr/local/bin/security-watch          the scanner
  usr/local/bin/blocked-module          refuses + reports blocked protocols
  etc/systemd/system/security-watch.*   daily timer
  etc/pacman.d/hooks/*.hook             post-update scan + rkhunter baseline refresh
  etc/sysctl.d/99-zz-hardening.conf     kernel hardening
  etc/modprobe.d/blocked-protocols.conf protocol block
  etc/rkhunter.conf.local               known false positives
  etc/lynis/custom.prf                  lynis profile
  etc/opensnitchd/rules/*.json          3 base allow rules (local DNS, resolver, clock)
install.sh        reference: how we put it all together (OpenSnitch last; backs up replaced files)
uninstall.sh      reference: removes it again
```

## Daily use

- **Notification "Post-update scan: all clear"** after an update: nothing to do.
- **Any other Security Watch notification:** read `sudo tail -40 /var/log/security-watch.log`, then [docs/08-triage.md](docs/08-triage.md).
- **OpenSnitch popup:** a program wants to go online. Allow it only if you know the program and why it needs the network. An app that suddenly can't connect is almost always a missed popup: delete its deny rule in OpenSnitch → Rules.
- **After you update**, run `./check.sh` too if you want to see the full picture yourself.

## Undo

Each doc has an **Undo** section for its own layer. `uninstall.sh` shows how we undo all of them at once.

## What this does *not* do

- It is no replacement for updates. Update often (`omarchy update`); Security Watch tells you when a security fix is waiting.
- It doesn't turn on Secure Boot or turn off autologin. Omarchy logs you in automatically after the disk password, so **the LUKS disk password is your login.** Pick a strong one.
- It doesn't send anything anywhere. All scans run locally; results stay in `/var/log/security-watch.log`.

## Credits

This guide only connects existing tools; the real work is done by their authors. Thank you:

| Project | By | Used for |
|---|---|---|
| [Omarchy](https://github.com/basecamp/omarchy) | David Heinemeier Hansson (DHH), Basecamp and contributors | the system this guide builds on |
| [Arch Linux](https://archlinux.org) and the [Arch Security Team](https://security.archlinux.org) | the Arch Linux community | packages, signed updates and the security advisories arch-audit reads |
| [Hyprland](https://hyprland.org) | Vaxry and contributors | the desktop; starts the OpenSnitch UI at login |
| [OpenSnitch](https://github.com/evilsocket/opensnitch) | Simone Margaritelli (evilsocket), maintained by Gustavo Iñiguez Goya and contributors | outgoing application firewall |
| [ufw](https://launchpad.net/ufw) | Canonical and contributors | incoming firewall |
| [Rootkit Hunter (rkhunter)](https://rkhunter.sourceforge.net) | the rkhunter project | rootkit and changed-file scan |
| [Lynis](https://github.com/CISOfy/lynis) | Michael Boelen and CISOfy | weekly hardening audit; the KRNL-6000 and NETW-3200 suggestions behind layers 4 and 5 |
| [arch-audit](https://gitlab.archlinux.org/archlinux/arch-audit) | Andrea Scarpino and the Arch Linux team | finds installed packages with known vulnerabilities |
| [bluetui](https://github.com/pythops/bluetui) | pythops | Bluetooth pairing that asks first |
| [systemd](https://systemd.io), [libnotify](https://gitlab.gnome.org/GNOME/libnotify), [pacman](https://gitlab.archlinux.org/pacman/pacman) | their authors | timer, desktop notifications, post-update hooks |
| [Linux kernel documentation](https://docs.kernel.org/admin-guide/sysctl/) | the kernel developers | what each hardening setting does |

Each tool keeps its own license; this repo contains none of their code, only configuration and small scripts that call them.

## Contributing

Found a false positive, a mistake, or something that works differently on your Omarchy? Open an issue or a pull request.
