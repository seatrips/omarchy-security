# 1. Baseline audit: where do you stand?

Before changing anything, check what Omarchy already gives you. Every command here only reads.

## What a fresh Omarchy already does well

| Check | Command | Good result |
|---|---|---|
| Full-disk encryption | `lsblk -o NAME,TYPE,FSTYPE` | a `crypt` device (LUKS2) under your root partition |
| Firewall for incoming traffic | `sudo ufw status verbose` | `Status: active`, `Default: deny (incoming)` |
| Nothing reachable from the network | `ss -tlnp` | only `127.0.0.1` / `[::1]` addresses |
| SSH server off | `systemctl is-enabled sshd` | `disabled` or `not-found` |
| Up to date | `checkupdates` (from `pacman-contrib`) | no output |
| Screen locks when idle | `~/.config/omarchy/` idle settings | locks after a few minutes |
| Package signatures | `grep SigLevel /etc/pacman.conf` | `Required` |

## Things worth knowing

- **Autologin.** Omarchy logs you straight in after the disk password. That makes the **disk password your only login password**: make it long.
- **AUR packages** are built from scripts written by anyone. List yours with `pacman -Qm` and keep the list short.
- **Passwordless sudo.** `sudo grep -r NOPASSWD /etc/sudoers /etc/sudoers.d`. Omarchy adds a few rules that each allow **one specific command** (for example its DNS, theme and timezone helpers). That is fine. A rule like `ALL=(ALL) NOPASSWD: ALL` is not.
- **docker group.** `groups` should not list `docker`: being in it is the same as having root without a password.
- **avahi-daemon** (UDP 5353) answers local-network discovery. It is needed for finding printers. If you never print, you can disable it; if you do, leave it.
- **Secure Boot** is often unsupported on laptops running Linux. Disk encryption still protects your data if the laptop is stolen while it is off.

## Deeper scan: Lynis

```bash
sudo pacman -S lynis
sudo lynis audit system
```

Lynis gives a **hardening index** (0-100) and a list of *warnings* (fix these) and *suggestions* (choose).
A fresh Omarchy with this guide applied scores around **70 with 0 warnings**.
Don't chase 100: many suggestions are aimed at servers and break desktop things. Layers 5 and 6 of this guide are the suggestions that are safe on a laptop.

Full report: `/var/log/lynis-report.dat`. Security Watch reruns Lynis every Sunday and alerts only on new *warnings*.

## Undo

Nothing to undo: this page only reads.
