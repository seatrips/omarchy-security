# 2. Bluetooth: pairing asks first

## The problem

Omarchy ships a user service, `bt-agent.service`, that registers a Bluetooth agent with the **NoInputNoOutput** capability and accepts every pairing request automatically.
Anyone in radio range can then pair a device (a keyboard, for example) without you confirming anything.

## The fix

Mask the service so nothing can start it again:

```bash
systemctl --user disable --now bt-agent.service
systemctl --user mask bt-agent.service
```

Check: `readlink ~/.config/systemd/user/bt-agent.service` prints `/dev/null`.

Pair devices with **bluetui** (Omarchy's Bluetooth menu) from now on. It shows the pairing request and asks you to confirm.

Security Watch checks every day that the mask is still there (an Omarchy update could bring the service back) and notifies you if it's gone.

## Undo

```bash
systemctl --user unmask bt-agent.service
systemctl --user enable --now bt-agent.service
```
