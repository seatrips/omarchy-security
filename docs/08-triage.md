# 8. When you get a notification

First step for every Security Watch alert:

```bash
sudo tail -40 /var/log/security-watch.log
```

| Notification | Meaning | What to do |
|---|---|---|
| **Post-update scan: all clear** | nothing new after the update | nothing |
| **Security updates available — run omarchy update** | an installed package has a known vulnerability and the fixed version is out | `omarchy update` |
| **Rootkit Hunter warning** | rkhunter saw something unusual | see below; don't whitelist without checking |
| **Lynis security warning** | a new hardening warning | `sudo lynis show details <TEST-ID>` |
| **System check warning: Failed service** | a service failed | `systemctl status <name>`, `journalctl -u <name> -b` |
| **Config needs merging** | an update shipped a new default config next to yours (`.pacnew`) | compare with `diff`, merge what's new, delete the `.pacnew` |
| **Listening on network** | a program opened a TCP port reachable from outside | find the program in the message; if you didn't expect it, stop/disable it. ufw still drops incoming, so it isn't exposed yet |
| **Passwordless sudo** | a new NOPASSWD rule appeared | a rule for **one specific command** from Omarchy is normal; `ALL` is not: find which package or person added it |
| **Firewall (ufw) is not active** / **OpenSnitch is not running** | a firewall is off | `sudo systemctl enable --now ufw` / `opensnitchd` |
| **sshd is enabled** | the SSH server will start at boot | `sudo systemctl disable --now sshd` unless you need it |
| **bt-agent … no longer masked** | an update brought Bluetooth auto-accept back | `systemctl --user mask bt-agent.service` |
| **Blocked network protocol: X** | a program tried to use a blocked protocol | if you know and need that program, delete its line in `/etc/modprobe.d/blocked-protocols.conf` |

## Checking an rkhunter warning

1. Read the exact line in `/var/log/rkhunter.log`: which file, which test.
2. **File properties changed** (hash, size, date): did an update just replace it? `pacman -Qo <file>` gives the package; `pacman -Qkk <package>` checks it against the package's own hashes. If pacman says it's fine, run `sudo rkhunter --propupd`.
3. **Hidden file or `/dev` file:** find what made it. `ls -la`, `file`, `pacman -Qo`, and for `/dev/shm` files check which program has them open: `sudo lsof <file>`.
4. Only when you know it's harmless, add a line to `/etc/rkhunter.conf.local` (`ALLOWHIDDENFILE=`, `ALLOWDEVFILE=`, `SCRIPTWHITELIST=`) with a comment saying what it is.
5. If you **can't** explain it: take the laptop off the network and ask for help before you do anything else.

## An app suddenly can't connect

Almost always OpenSnitch: you missed its popup and it's now denied for 12 hours. OpenSnitch → **Rules** → delete that app's deny rule → restart the app → allow it in the popup. See [07-opensnitch-last.md](07-opensnitch-last.md).
