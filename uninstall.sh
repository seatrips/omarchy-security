#!/usr/bin/env bash
# Removes what install.sh added. Leaves the packages and ufw installed
# (ufw is part of Omarchy). Reboot afterwards so the sysctl values reset.
set -uo pipefail

echo "==> Security Watch and post-update hooks"
sudo systemctl disable --now security-watch.timer
sudo rm -f /etc/systemd/system/security-watch.{service,timer} \
  /usr/local/bin/security-watch \
  /etc/pacman.d/hooks/zz-security-watch.hook /etc/pacman.d/hooks/rkhunter-propupd.hook
sudo systemctl daemon-reload

echo "==> Kernel hardening and protocol block"
sudo rm -f /etc/sysctl.d/99-zz-hardening.conf /etc/modprobe.d/blocked-protocols.conf \
  /usr/local/bin/blocked-module
echo "    /etc/ufw/sysctl.conf keeps log_martians=1 (harmless); restore its .bak.* file if you want the old one."

echo "==> OpenSnitch"
sudo systemctl disable --now opensnitchd
pkill -x opensnitch-ui
sed -i '/opensnitch-ui --background/d' ~/.config/hypr/autostart.lua 2>/dev/null

echo "==> Bluetooth auto-accept stays masked. To bring it back:"
echo "    systemctl --user unmask bt-agent.service && systemctl --user enable --now bt-agent.service"
echo
echo "Done. Reboot to reset the kernel settings."
