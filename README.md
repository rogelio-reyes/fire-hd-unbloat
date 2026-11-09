# fire-hd-unbloat

Turn an Amazon Fire HD 8 into a cleaner Android tablet from a Mac: disable Amazon's apps, install the Google Play Store and use a normal launcher. Some protected items (lock screen ads, Amazon's home button) can't be changed without root; see [docs/troubleshooting.md](docs/troubleshooting.md). No root, no bricking risk, and every change can be undone.

Works on every Fire HD 8 generation. Should work on other Fire tablets too, since it only touches packages it finds.

> Want to replace Fire OS completely with LineageOS? Only the 2016-2018 models can do that. See [docs/models.md](docs/models.md).

## What you need

- A Mac (Linux works too) with [Homebrew](https://brew.sh)
- A USB **data** cable for the tablet
- About 20 minutes

## 1. Prepare the tablet

1. Settings > Device Options > About Fire Tablet. Tap **Serial Number** seven times to unlock Developer Options.
2. Settings > Device Options > Developer Options. Turn on **USB debugging** (on some versions it's called **Enable ADB**).
3. Plug the tablet into your Mac. Unlock the screen and tap **Allow** on the USB debugging prompt.

## 2. Prepare the Mac

```bash
brew install android-platform-tools
git clone https://github.com/rogelio-reyes/fire-hd-unbloat.git
cd fire-hd-unbloat
chmod +x scripts/*.sh
```

## 3. Run the steps

| Step | Command | What it does | Changes the tablet? |
|---|---|---|---|
| 0 | `./scripts/00-check.sh` | Identifies your model and what it supports | No |
| 1 | `./scripts/01-backup.sh` | Records every package's state so you can undo | No |
| 2 | `./scripts/02-debloat.sh` | Shows what it would disable (dry run) | No |
| 2 | `./scripts/02-debloat.sh --tier recommended --apply` | Disables Amazon apps and ads | Yes, reversible |
| 3 | `./scripts/03-install-play-store.sh` | Installs Google Play from APKs you download ([apks/README.md](apks/README.md)) | Yes |
| 4 | `./scripts/04-replace-launcher.sh --apply` | Tries to disable Amazon's launcher so Home opens yours. Fire OS 7 blocks this, so open your launcher from the app list | Yes, reversible |

**Tiers** in step 2 build on each other:

- `safe`: ads, Shopping, Prime Video, Music, Audible, Photos and other standalone apps
- `recommended`: adds Alexa, Silk, Kindle, Amazon Kids. Install replacements first.
- `aggressive`: adds the Amazon Appstore and Fire OS updates. Read [lists/aggressive.txt](lists/aggressive.txt) before using.

Edit the files in `lists/` to choose exactly what to disable.

## Tested on

Fire HD 8 (2020, KFONWI), Fire OS 7.3.3.1, macOS bash 3.2. Disabled 10 of 12 `safe` packages; the lock screen ads and Help app are protected. Play Store, Play Services and Nova Launcher installed. Home still opens Amazon's launcher.

## Undo

```bash
./scripts/restore.sh            # undo everything recorded in your latest backup
./scripts/restore.sh --all      # re-enable every package this toolkit knows about
```

A factory reset (Settings > Device Options) also restores Fire OS completely.

## Using it with Claude Code

Open Claude Code in this folder and ask it to walk you through the steps. [CLAUDE.md](CLAUDE.md) tells it how to work safely here: backup first, dry runs before changes, and no running steps without your approval.

## How it works

Everything runs over ADB with `pm disable-user --user 0`. Nothing is deleted from the system partition. If Fire OS blocks disabling an app, the script hides it for your user with `pm uninstall -k --user 0`, which `restore.sh` reverses with `cmd package install-existing`.

## Contributing

Package names change between Fire OS versions. If something is missing, wrong, or breaks your tablet, open an issue with your model code and Fire OS version (both shown by `00-check.sh`).

## Disclaimer

Not affiliated with Amazon or Google. Use at your own risk. Modifying your tablet's software may affect warranty or support.

## License

MIT
