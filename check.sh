#!/usr/bin/env bash
# Read-only check: is every safety layer on, and did the last update leave
# anything behind? Runs as your normal user, no sudo, changes nothing.
#   ./check.sh            status of every layer + checks since the last update
set -uo pipefail

ok()   { printf '  \e[32mOK\e[0m    %s\n' "$*"; }
bad()  { printf '  \e[31mFIX\e[0m   %s\n' "$*"; problems=$((problems+1)); }
info() { printf '  \e[33mLOOK\e[0m  %s\n' "$*"; }
problems=0

echo "== Safety layers"
lsblk -o TYPE | grep -q crypt && ok "Disk is encrypted (LUKS)" || bad "No encrypted disk found"
systemctl is-active -q ufw && ok "ufw firewall active" || bad "ufw is not active"
systemctl is-active -q opensnitchd && ok "OpenSnitch running" || bad "OpenSnitch is not running"
pgrep -x opensnitch-ui >/dev/null && ok "OpenSnitch popups (UI) running" || bad "opensnitch-ui is not running: no popups, and OpenSnitch allows everything"
systemctl is-enabled -q sshd 2>/dev/null && bad "sshd is enabled" || ok "sshd off"
[[ $(readlink ~/.config/systemd/user/bt-agent.service) == /dev/null ]] \
  && ok "Bluetooth auto-accept masked" || bad "bt-agent (Bluetooth auto-accept) is not masked"
systemctl is-active -q security-watch.timer && ok "Security Watch timer active" || bad "security-watch.timer is not active"
[[ -e /etc/pacman.d/hooks/zz-security-watch.hook ]] && ok "Post-update scan hook installed" || bad "Post-update hook missing"

want="kernel.kptr_restrict=2 net.core.bpf_jit_harden=2 dev.tty.ldisc_autoload=0 fs.protected_fifos=2
fs.protected_regular=2 fs.suid_dumpable=0 net.ipv4.conf.all.log_martians=1 net.ipv4.conf.default.log_martians=1"
for kv in $want; do
  k=${kv%=*} v=${kv#*=}
  cur=$(sysctl -n "$k" 2>/dev/null)
  [[ -z $cur ]] && continue   # readable by root only (bpf_jit_harden)
  [[ $cur == "$v" ]] || bad "sysctl $k is $cur, want $v"
done
ok "Kernel hardening values checked"
[[ -e /etc/modprobe.d/blocked-protocols.conf ]] && ok "Unused protocols blocked" || bad "blocked-protocols.conf missing"

echo
echo "== Since the last update"
last=$(grep -E '\[ALPM\] transaction completed' /var/log/pacman.log | tail -1 | cut -c2-25)
start=$(grep -E '\[ALPM\] transaction started' /var/log/pacman.log | tail -1 | cut -c2-25)
echo "  Last pacman transaction: ${start:-none}"
if [[ -n $start ]]; then
  awk -v s="[$start" 'index($0, s) == 1 {f=1} f' /var/log/pacman.log \
    | grep -iE 'warning|error' | sed 's/^/  LOOK  /' | head -20
fi

f=$(systemctl --failed --no-legend --plain | awk '{print $1}')
[[ -z $f ]] && ok "No failed system services" || bad "Failed system services: $f"
f=$(systemctl --user --failed --no-legend --plain | awk '{print $1}')
[[ -z $f ]] && ok "No failed user services" || info "Failed user services: $f"

f=$(arch-audit --upgradable 2>/dev/null)
[[ -z $f ]] && ok "No vulnerable packages with a fix waiting" || bad "Security updates available:"$'\n'"$f"

f=$(find /etc /usr/local -xdev \( -name '*.pacnew' -o -name '*.pacsave' \) 2>/dev/null)
[[ -z $f ]] && ok "No .pacnew/.pacsave configs to merge" || info "Configs to merge: $f"

f=$(pacman -Qdtq 2>/dev/null)
[[ -z $f ]] && ok "No orphan packages" || info "Orphans (not needed by anything): $(echo $f)"

f=$(ss -tlnpH | awk '$4 !~ /^(127\.|\[::1\]|172\.17\.0\.1:)/ && $4 !~ /%lo:/ {print $4" "$6}')
[[ -z $f ]] && ok "No TCP port open to the network" || info "TCP ports open to the network (ufw still drops incoming):"$'\n'"$f"

if [[ -r /etc/sudoers.d ]]; then
  f=$(grep -rhs NOPASSWD /etc/sudoers /etc/sudoers.d | grep -v '^\s*#')
  [[ -z $f ]] && ok "No passwordless sudo rules" || info "NOPASSWD rules (single commands are normal on Omarchy):"$'\n'"$f"
else
  info "Passwordless sudo: not readable without root; Security Watch checks it daily"
fi

if [[ -n $last ]]; then
  since=$(date -d "${last/T/ }" '+%F %T' 2>/dev/null)
  if [[ -n $since ]]; then
    n=$(journalctl -b -p err --since "$since" -q --no-pager 2>/dev/null | wc -l)
    (( n == 0 )) && ok "No errors in the journal since the update" || info "$n error lines in the journal since the update: journalctl -b -p err --since '$since'"
    c=$(coredumpctl list --since "$since" --no-legend -q 2>/dev/null | wc -l)
    (( c == 0 )) && ok "No crashes since the update" || info "$c crash(es) since the update: coredumpctl list"
  fi
fi

echo
(( problems == 0 )) && echo "All layers on." || echo "$problems thing(s) to fix: see docs/ for each one."
echo "Security Watch log: /var/log/security-watch.log (sudo tail -30 /var/log/security-watch.log)"
