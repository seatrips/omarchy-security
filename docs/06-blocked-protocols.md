# 6. Unused network protocols blocked

The Linux kernel loads protocol modules on demand: any program can open a DCCP, SCTP, RDS or TIPC socket and the module loads itself.
A laptop never uses these, and they have a history of kernel bugs reachable by normal users. Lynis test NETW-3200 suggests blocking them.

## Blocked, but not silently

A plain `blacklist` line would make a program fail with no explanation. Here, loading one of them runs a small helper instead. The helper:

1. refuses the load
2. logs it: `journalctl -t blocked-module`
3. shows a desktop notification: **"Blocked network protocol: sctp"** with how to allow it

So if something you use ever needs one, you know right away and can fix it with one line.

`files/etc/modprobe.d/blocked-protocols.conf`:

```
install dccp /usr/local/bin/blocked-module dccp
install sctp /usr/local/bin/blocked-module sctp
install rds  /usr/local/bin/blocked-module rds
install tipc /usr/local/bin/blocked-module tipc
```

Install:

```bash
sudo install -m755 files/usr/local/bin/blocked-module /usr/local/bin/blocked-module
sudo sed -i "s/^NOTIFY_USER=.*/NOTIFY_USER=$USER/" /usr/local/bin/blocked-module
sudo install -Dm644 files/etc/modprobe.d/blocked-protocols.conf /etc/modprobe.d/blocked-protocols.conf
```

Test: `python3 -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM, 132)'` (132 = SCTP) should fail and show the notification.

## Allow one again

Delete its line from `/etc/modprobe.d/blocked-protocols.conf`. No reboot needed.

## Undo

```bash
sudo rm /etc/modprobe.d/blocked-protocols.conf /usr/local/bin/blocked-module
```
