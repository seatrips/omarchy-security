# 9. Habits

The tools above catch problems. These habits prevent them.

## Updates

- Update often: `omarchy update`. Wait for the "Post-update scan" notification.
- After an update, run `./check.sh` if you want the full picture.
- Merge `.pacnew` files instead of ignoring them: they can hold security fixes to the default config.
- Reboot after a kernel update, then check the hardening is still on (`./check.sh`).

## Installing software

- Prefer the official repos (`pacman`) over the AUR. For an AUR package, read its PKGBUILD before building.
- `curl ... | bash`: read the script first.
- A new app gets an OpenSnitch popup the first time it goes online. Allow it per program and, for interpreters (python, node), per script and host. Never allow an interpreter everywhere.
- Closed-source apps that talk to their vendor's servers: know what they send before you allow them.
- Remove what you no longer use (`pacman -Rns`) and clean orphans (`pacman -Qdtq`).

## Services and ports

- Keep sshd off unless you need it.
- Don't join the `docker` group (it gives root without a password). If you don't use Docker, disable it.
- Open ufw ports only while you need them.

## Secrets and git

- Never commit passwords, API keys, tokens, cookies or browser/app session folders. Add them to `.gitignore` *before* the first `git add`.
- Create repos **private** by default (`gh repo create --private`). Make one public only on purpose, after checking its full history: `git log -p` and a secret scanner like `gitleaks`.
- Something secret pushed by mistake: treat it as leaked. Rotate it first, then clean the history.

## Physical

- A strong LUKS password (it's also your login, because of autologin).
- Lock the screen when you walk away (Omarchy menu → System → Lock).
- Accept Bluetooth pairing only for devices you're pairing right now.
