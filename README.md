# Omarchy Security Guide

How to make an [Omarchy](https://omarchy.org) laptop as safe as possible for private and work use, and keep it that way.
It covers what was checked, what was changed and why, and an automatic security scan that runs after every update.

It works on any Omarchy install (Arch Linux + Hyprland), on any hardware.
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
stopped or noticed early. This repo is how we did it, shared so other Omarchy users can do the same.

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

## Quick start

> [!IMPORTANT]
> **Install OpenSnitch last, and stay at the screen when you do.** It shows a popup for every program
> that goes online for the first time. A popup you miss for 30 seconds becomes a **deny rule for 12 hours**,
> and that program looks broken with no clue why. `install.sh` sets up OpenSnitch as the very last step and
> waits for you to press Enter. Then answer the popups (arch-audit first).

```bash
git clone https://github.com/seatrips/omarchy-security ~/omarchy-security
cd ~/omarchy-security
less install.sh        # read it first: it uses sudo
./install.sh           # installs every layer, OpenSnitch last; backs up any file it replaces
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
- **OpenSnitch popup:** a program wants to go online. Allow it only if you know the program and why it needs the network. An app that suddenly can't connect is almost always a missed popup: delete its deny rule in OpenSnitch → Rules.
- **After you update**, run `./check.sh` too if you want to see the full picture yourself.

## Undo

`./uninstall.sh` removes the scanner, the hooks, the kernel settings and the protocol block, and turns OpenSnitch off.
Bluetooth auto-accept stays off unless you turn it back on (the script prints how). Reboot afterwards.
Each doc also has an **Undo** section for its own layer.

## What this does *not* do

- It is no replacement for updates. Update often (`omarchy update`); Security Watch tells you when a security fix is waiting.
- It doesn't turn on Secure Boot or turn off autologin. Omarchy logs you in automatically after the disk password, so **the LUKS disk password is your login.** Pick a strong one.
- It doesn't send anything anywhere. All scans run locally; results stay in `/var/log/security-watch.log`.

## Contributing

Found a false positive, a mistake, or something that works differently on your Omarchy? Open an issue or a pull request.
