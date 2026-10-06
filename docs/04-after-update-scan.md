# 4. Scan after every update

Updates are when things change: a new service gets enabled, a port opens, a config needs merging, a unit fails, a setting you hardened gets reset.
So every update is followed by a full scan, automatically.

## Automatic: the pacman hook

`files/etc/pacman.d/hooks/zz-security-watch.hook` runs after **every** pacman transaction (install, upgrade, remove), including `omarchy update` and `yay`:

```ini
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Queueing Security Watch post-update scan...
When = PostTransaction
Exec = /bin/sh -c 'touch /var/lib/security-watch/after-update; /usr/bin/systemctl start --no-block security-watch.service'
```

- The `zz-` prefix makes it run **after** `rkhunter-propupd.hook`, so rkhunter checks against the fresh baseline and doesn't flag every updated file.
- `--no-block`: the update finishes right away; the scan runs in the background.
- The `after-update` flag file tells the scanner this run follows an update.

After the scan you get **one** notification:

- **"Post-update scan: all clear"**: nothing new. Nothing to do.
- or the findings: a vulnerable package, a rootkit warning, a failed service, a `.pacnew` file, a new open port, sshd enabled, ufw or OpenSnitch off, Bluetooth auto-accept back.

Install:

```bash
sudo install -Dm644 files/etc/pacman.d/hooks/zz-security-watch.hook /etc/pacman.d/hooks/zz-security-watch.hook
```

(Needs Security Watch from [03-security-watch.md](03-security-watch.md).)

## Manual: `./check.sh`

For the full picture after an update, run `./check.sh` as your normal user. It changes nothing and needs no sudo.

It shows:

1. **Every layer:** encryption, ufw, OpenSnitch + its UI, sshd off, Bluetooth mask, Security Watch timer, post-update hook, the kernel values, the protocol block.
2. **Since the last update:**
   - warnings and errors in `/var/log/pacman.log` for the last transaction
   - failed system and user services
   - `arch-audit --upgradable`
   - `.pacnew` / `.pacsave` files to merge
   - orphan packages (`pacman -Qdtq`)
   - TCP ports open to the network
   - errors in the journal and crashes (`coredumpctl`) since the update

`OK` = fine, `LOOK` = worth a glance, `FIX` = a layer is off.

## Doing it fully by hand

```bash
tac /var/log/pacman.log | sed '/transaction started/q' | tac | grep -iE 'warning|error'
systemctl --failed; systemctl --user --failed
arch-audit --upgradable
find /etc -name '*.pacnew' -o -name '*.pacsave'
pacman -Qdtq
ss -tlnp
journalctl -b -p err --since "1 hour ago"
coredumpctl list --since "1 hour ago"
sudo tail -40 /var/log/security-watch.log
```

## Undo

```bash
sudo rm /etc/pacman.d/hooks/zz-security-watch.hook
```
