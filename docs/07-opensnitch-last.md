# 7. OpenSnitch, last: the firewall for outgoing traffic

> **Install OpenSnitch last, when you have a few minutes to sit at the screen.**
> Every program that goes online for the first time shows a popup. A popup you don't answer
> within **30 seconds** becomes a **deny rule that lasts 12 hours**. Install it in the middle of
> other setup (packages downloading, apps starting for the first time) and you miss popups.
> Those programs then look broken for half a day, with no error that points to OpenSnitch.
> So set up everything else first, then OpenSnitch, then stay and answer the first round of popups.
> `install.sh` does it in that order and waits for you to press Enter.

## OpenSnitch (outgoing, per program)

ufw (see [01-baseline-audit.md](01-baseline-audit.md)) only guards incoming traffic and lets every program go online. **OpenSnitch** asks the first time a program connects, so you see who is talking to the internet and decide.

Copy the base rules (below) first, then:

```bash
sudo pacman -S opensnitch
echo 'o.launch_on_start("opensnitch-ui --background")' >> ~/.config/hypr/autostart.lua   # UI at every login
setsid opensnitch-ui --background >/dev/null 2>&1 &                                     # UI now
sudo systemctl enable --now opensnitchd
```

**OpenSnitch only protects you while the UI is running.** Without the UI there are no popups, and the daemon falls back to `DefaultAction` in `/etc/opensnitchd/default-config.json`, which is **allow** by default. So if the UI isn't running, everything gets through, without any warning. `check.sh` checks that the UI is running.

Then, still at the screen, run a first scan (`sudo systemctl start security-watch`) and answer **arch-audit's** popup with *Allow, always*. Security Watch needs it to download the Arch security list. Then open your usual apps one by one and answer each popup.

### Base rules

Copy the three rules from `files/etc/opensnitchd/rules/` to `/etc/opensnitchd/rules/` (mode 600). They allow:

- `000-allow-local-dns`: any program may ask the local DNS stub (127.0.0.53:53). Only systemd-resolved actually goes out.
- `000-allow-systemd-resolved`: the system resolver.
- `000-allow-systemd-timesyncd`: clock sync.

Without them every program's first DNS lookup triggers a popup.

### Important: how a missed popup behaves

The UI's defaults are: popup timeout **30 seconds**, then **deny**, and the rule it makes lasts **12 hours**.
If you miss a popup, the app is cut off from the network for 12 hours and looks broken (endless loading, a login that never finishes, `ERR_TIMED_OUT`).

**Fix:** open OpenSnitch → **Rules**, find the deny rule for that program, and delete it. Then restart the app and answer the popup.

You can change these in the UI's Preferences (*Pop-ups* tab): a longer timeout, or "once" as the default duration so a missed popup only blocks that one connection.
(In `~/.config/opensnitch/settings.conf`, `default_duration` is a position in the list once, 30s, 5m, 15m, 30m, 1h, 12h, until restart, counting from 0. The default `6` means **12h**, even though a comment in OpenSnitch's own code calls it "until restart".)

### Good rules

- **Allow always, per program path**, for programs you trust: your browser, NetworkManager, pacman, git (`git-remote-http`), curl.
- `arch-audit` needs to download the Arch security list: allow it, or Security Watch can't check for vulnerable packages.
- **Never allow a language interpreter everywhere** (`/usr/bin/python3`, `node`, `bun`): that lets *any* script go anywhere. Make a narrow rule instead: the interpreter **plus** the script's command line **plus** the destination host. In the rule editor: tick *Process path*, *Command line* (or part of it) and *To this host*.
Host names only match when OpenSnitch can see the DNS answers (it does with its default eBPF mode). If a host rule never matches, use the IP range or leave the host out and rely on the command line.
- Add rules in the OpenSnitch UI (**Rules** tab → **+**). Don't delete a rule while you're still editing it.

## Undo

```bash
sudo systemctl disable --now opensnitchd
pkill -x opensnitch-ui
sed -i '/opensnitch-ui --background/d' ~/.config/hypr/autostart.lua
```
