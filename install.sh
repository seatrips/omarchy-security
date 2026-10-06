#!/usr/bin/env bash
# REFERENCE, not a one-click installer: this is what we ran on our own machine
# (Omarchy 4.0.x). Other hardware or Omarchy versions can differ. Read it first,
# or let your AI assistant check your system and adapt it. See README.md.
# Installs every safety layer from this guide on an Omarchy (Arch) laptop:
#   1. Bluetooth: mask Omarchy's auto-accept pairing agent
#   2. ufw firewall on for incoming traffic
#   3. Security Watch: daily arch-audit + rkhunter, weekly lynis, health checks
#   4. Post-update scan after every pacman transaction
#   5. Kernel hardening (7 sysctl values) + ufw log_martians fix
#   6. Unused network protocols blocked, with a notification if something needs one
#   7. OpenSnitch application firewall, LAST: missed popups become 12-hour denies
# Safe to run again: every file it replaces is backed up to *.bak.<timestamp> first.
# Undo everything with ./uninstall.sh.
set -euo pipefail
cd "$(dirname "$0")"
ts=$(date +%s)
F=files

sinstall() { # sinstall MODE SRC DEST
  [[ -e $3 ]] && sudo cp -a "$3" "$3.bak.$ts"
  sudo install -D -m"$1" "$2" "$3"
}

# Put the current user into a script that has NOTIFY_USER=CHANGEME
sinstall_user() { # sinstall_user SRC DEST
  local tmp
  tmp=$(mktemp)
  sed "s/^NOTIFY_USER=.*/NOTIFY_USER=$USER/" "$1" > "$tmp"
  sinstall 755 "$tmp" "$2"
  rm -f "$tmp"
}

echo "==> Packages (needs sudo)"
sudo pacman -S --needed --noconfirm ufw opensnitch rkhunter lynis arch-audit libnotify

echo "==> 1. Bluetooth: stop auto-accepting pairing requests"
systemctl --user disable --now bt-agent.service 2>/dev/null || true
systemctl --user mask bt-agent.service
echo "    Pair devices that need a PIN or confirmation with bluetoothctl in a terminal (docs/02-bluetooth.md)."

echo "==> 2. ufw on (incoming dropped)"
sudo systemctl enable --now ufw
sudo ufw --force enable >/dev/null

echo "==> 3. Security Watch (notifies $USER)"
sinstall 644 $F/etc/rkhunter.conf.local /etc/rkhunter.conf.local
sinstall 644 $F/etc/lynis/custom.prf /etc/lynis/custom.prf
sinstall_user $F/usr/local/bin/security-watch /usr/local/bin/security-watch
sinstall 644 $F/etc/systemd/system/security-watch.service /etc/systemd/system/security-watch.service
sinstall 644 $F/etc/systemd/system/security-watch.timer /etc/systemd/system/security-watch.timer
sudo rkhunter --propupd --nolog   # rkhunter's "known good" file baseline

echo "==> 4. Post-update scan (pacman hooks)"
# rkhunter-propupd refreshes the baseline first; zz-security-watch sorts after it.
sinstall 644 $F/etc/pacman.d/hooks/rkhunter-propupd.hook /etc/pacman.d/hooks/rkhunter-propupd.hook
sinstall 644 $F/etc/pacman.d/hooks/zz-security-watch.hook /etc/pacman.d/hooks/zz-security-watch.hook
sudo systemctl daemon-reload
sudo systemctl enable --now security-watch.timer

echo "==> 5. Kernel hardening"
sinstall 644 $F/etc/sysctl.d/99-zz-hardening.conf /etc/sysctl.d/99-zz-hardening.conf
sudo sysctl -q -p /etc/sysctl.d/99-zz-hardening.conf
# ufw sets log_martians back to 0 every time it starts, after sysctl.d; fix it at the source.
if grep -q 'log_martians=0' /etc/ufw/sysctl.conf; then
  sudo cp -a /etc/ufw/sysctl.conf "/etc/ufw/sysctl.conf.bak.$ts"
  sudo sed -i 's|^\(net/ipv4/conf/[a-z]*/log_martians\)=0|\1=1|' /etc/ufw/sysctl.conf
  sudo ufw reload >/dev/null
fi

echo "==> 6. Block unused network protocols (DCCP, SCTP, RDS, TIPC)"
sinstall_user $F/usr/local/bin/blocked-module /usr/local/bin/blocked-module
sinstall 644 $F/etc/modprobe.d/blocked-protocols.conf /etc/modprobe.d/blocked-protocols.conf

echo "==> 7. OpenSnitch application firewall: LAST on purpose"
cat <<'MSG'

    OpenSnitch asks before any program goes online. A popup you don't answer
    within 30 seconds becomes a DENY rule that lasts 12 hours, and that program
    then looks broken. That's why it comes last: nothing else is installing now.

    Have a few minutes and stay at the screen. Popups will come right away
    (arch-audit for the first scan, then your browser, mail, chat...).
    Allow programs you know. Details: docs/07-opensnitch-last.md

MSG
read -rp "    Press Enter to start OpenSnitch now, or Ctrl+C to do it later... "
for rule in $F/etc/opensnitchd/rules/*.json; do
  sinstall 600 "$rule" "/etc/opensnitchd/rules/$(basename "$rule")"
done
if ! grep -q 'opensnitch-ui' ~/.config/hypr/autostart.lua 2>/dev/null; then
  mkdir -p ~/.config/hypr
  [[ -e ~/.config/hypr/autostart.lua ]] && cp ~/.config/hypr/autostart.lua ~/.config/hypr/autostart.lua.bak.$ts
  printf 'o.launch_on_start("opensnitch-ui --background")\n' >> ~/.config/hypr/autostart.lua
fi
# Without the UI there are no popups and the daemon allows everything (DefaultAction).
pgrep -x opensnitch-ui >/dev/null || (setsid opensnitch-ui --background >/dev/null 2>&1 &)
sleep 3
sudo systemctl enable --now opensnitchd
# First scan now, while you're watching: answer arch-audit's popup with "Allow, always".
sudo systemctl start --no-block security-watch

echo
echo "Done. Next:"
echo "  - Answer the OpenSnitch popups now (arch-audit first)."
echo "  - Check all layers: ./check.sh   (scan log: /var/log/security-watch.log)"
