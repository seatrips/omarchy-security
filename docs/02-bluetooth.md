# 2. Bluetooth: pairing asks first

## What Omarchy does

Omarchy ships a user service, `bt-agent.service` (package `omarchy-settings`), that registers a Bluetooth agent with the **NoInputNoOutput** capability: it accepts pairing requests without asking you. That makes pairing headphones easy.

Omarchy limits the risk well: the adapter is only **pairable while you have the Bluetooth panel open and are scanning**. The rest of the time BlueZ refuses pairing attempts (`bluetoothctl show` → `Pairable: no`).

## Why we changed it anyway

During that pairing window, any device in range that asks to pair is accepted, and you don't see a passkey to confirm it's the device you meant. The risk is small, but a fake keyboard paired that way could type commands. Masking the agent means **every pairing shows you a confirmation**. The cost is one extra click when you pair.

## The fix

Mask the service so nothing can start it again:

```bash
systemctl --user disable --now bt-agent.service
systemctl --user mask bt-agent.service
```

Check: `readlink ~/.config/systemd/user/bt-agent.service` prints `/dev/null`.

### Pairing afterwards

Omarchy's Bluetooth panel pairs by running `bluetoothctl pair` in the background, and it relies on bt-agent to answer pairing questions.
With bt-agent masked, nothing answers them from the panel, so:

- devices that pair without a code (most headphones and speakers) usually still pair from the panel;
- devices that need a PIN or a passkey confirmation (keyboards, phones) may fail there. Pair those in a terminal instead. `bluetoothctl` then shows the code and asks you:

```bash
bluetoothctl
  scan on              # wait until your device shows up, note its address
  pair AA:BB:CC:DD:EE:FF   # check the passkey matches the device, answer yes
  trust AA:BB:CC:DD:EE:FF
  connect AA:BB:CC:DD:EE:FF
  scan off
  exit
```

We haven't tested every kind of device. If you pair new devices often and the risk above doesn't worry you, keeping Omarchy's default is a reasonable choice too.

Security Watch checks every day that the mask is still there (an Omarchy update could bring the service back) and notifies you if it's gone.

## Undo

```bash
systemctl --user unmask bt-agent.service
systemctl --user enable --now bt-agent.service
```
