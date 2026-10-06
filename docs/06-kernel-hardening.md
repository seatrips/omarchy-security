# 6. Kernel hardening

Lynis test KRNL-6000 suggests about 11 kernel settings. Seven of them are safe on a desktop and have no visible effect; they close common exploit aids.

`files/etc/sysctl.d/99-zz-hardening.conf`:

| Setting | Value | What it does |
|---|---|---|
| `kernel.kptr_restrict` | 2 | hides kernel memory addresses, even from root, which makes kernel exploits harder |
| `net.core.bpf_jit_harden` | 2 | hardens the BPF JIT compiler against JIT-spraying |
| `dev.tty.ldisc_autoload` | 0 | stops unprivileged users from loading old TTY line-discipline modules, a common exploit path |
| `fs.protected_fifos` | 2 | blocks FIFO tricks in shared directories like `/tmp` |
| `fs.protected_regular` | 2 | the same for regular files in `/tmp` |
| `fs.suid_dumpable` | 0 | setuid programs don't write core dumps (which could hold secrets); normal programs still do |
| `net.ipv4.conf.{all,default}.log_martians` | 1 | logs packets with impossible source addresses |

The `99-zz-` name sorts it after Omarchy's own `99-omarchy-sysctl.conf`, so these values win.

```bash
sudo install -Dm644 files/etc/sysctl.d/99-zz-hardening.conf /etc/sysctl.d/99-zz-hardening.conf
sudo sysctl -p /etc/sysctl.d/99-zz-hardening.conf
```

## Gotcha: ufw resets `log_martians`

ufw applies its own `/etc/ufw/sysctl.conf` every time it starts, **after** `sysctl.d`, and that file sets `log_martians=0`.
So the value looks right after `sysctl -p` but is back to 0 after every reboot. Fix it in ufw's file:

```bash
sudo cp -a /etc/ufw/sysctl.conf /etc/ufw/sysctl.conf.bak
sudo sed -i 's|^\(net/ipv4/conf/[a-z]*/log_martians\)=0|\1=1|' /etc/ufw/sysctl.conf
sudo ufw reload
```

**Always verify hardening after a reboot**, not just right after applying it. `./check.sh` does this.

## Skipped on purpose

| Setting | Why not |
|---|---|
| `kernel.modules_disabled=1` | no module can load after boot: USB devices, WiFi adapters and VPNs that need a module would stop working |
| `kernel.sysrq=0` | Omarchy already sets a safer value; SysRq is useful to recover a frozen system |
| `net.ipv4.ip_forward=0` | Docker and VPN tools need forwarding |
| `kernel.unprivileged_bpf_disabled` | already restricted by default on Arch |

## Undo

```bash
sudo rm /etc/sysctl.d/99-zz-hardening.conf
sudo cp -a /etc/ufw/sysctl.conf.bak /etc/ufw/sysctl.conf   # optional
reboot
```
