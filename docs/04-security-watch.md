# 4. Security Watch: daily scans

A small script (`files/usr/local/bin/security-watch`) run by a systemd timer. It scans and **only notifies for findings it hasn't reported before**.

## What it checks

| When | Tool | Finds |
|---|---|---|
| daily | `arch-audit --upgradable` | installed packages with a known vulnerability **that an update fixes** |
| daily | `rkhunter` | rootkits, changed system binaries, suspicious files in `/dev`, hidden files |
| Sundays | `lynis` | new hardening *warnings* |
| daily + after updates | health checks | failed services, `.pacnew` configs to merge, TCP ports open to the network, passwordless sudo, ufw / OpenSnitch off, sshd on, Bluetooth auto-accept back |

## Install by hand

```bash
sudo pacman -S rkhunter lynis arch-audit libnotify
sudo install -m755 files/usr/local/bin/security-watch /usr/local/bin/security-watch
sudo sed -i "s/^NOTIFY_USER=.*/NOTIFY_USER=$USER/" /usr/local/bin/security-watch
sudo install -m644 files/etc/systemd/system/security-watch.{service,timer} /etc/systemd/system/
sudo install -Dm644 files/etc/rkhunter.conf.local /etc/rkhunter.conf.local
sudo install -Dm644 files/etc/lynis/custom.prf /etc/lynis/custom.prf
sudo install -Dm644 files/etc/pacman.d/hooks/rkhunter-propupd.hook /etc/pacman.d/hooks/rkhunter-propupd.hook
sudo rkhunter --propupd --nolog
sudo systemctl daemon-reload
sudo systemctl enable --now security-watch.timer
sudo systemctl start security-watch   # first run
```

## How it works

- **Timer:** daily, 10 min after boot, `Persistent=true` (a day missed while the laptop was off runs at next boot). It runs at low CPU and disk priority.
- **"New only":** each check writes its findings to `/var/lib/security-watch/<check>.current` and compares with `<check>.seen`. Only lines not seen before trigger a notification.
- A finding counts as "seen" **only when the notification was delivered**. If you were logged out, you get it next time.
- A fixed finding is forgotten, so it alerts again if it ever comes back.
- **Log:** `/var/log/security-watch.log`, root-only (`sudo tail -40 /var/log/security-watch.log`).
- **rkhunter baseline:** rkhunter compares system files with a stored list of hashes. Updates change those files, so `rkhunter-propupd.hook` refreshes the list after every pacman transaction. Without it you'd get a warning for every updated binary.

## False positives

`files/etc/rkhunter.conf.local` whitelists things that are normal on Arch/Omarchy: `egrep`/`fgrep`/`ldd` being shell scripts, two hidden Kerberos man pages, `/etc/.updated`, EasyEffects' shared memory in `/dev/shm`, and the sshd checks (sshd is off).

`files/etc/lynis/custom.prf` skips PKGS-7322 (vulnerable packages *without* a fix yet): you can't act on those, and arch-audit already reports the moment a fix exists.

Whitelist a new warning **only after you've checked it**: see [08-triage.md](08-triage.md).

## Undo

```bash
sudo systemctl disable --now security-watch.timer
sudo rm /usr/local/bin/security-watch /etc/systemd/system/security-watch.{service,timer} \
  /etc/pacman.d/hooks/rkhunter-propupd.hook
sudo systemctl daemon-reload
```
