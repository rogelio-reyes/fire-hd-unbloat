# Working in this repo

This toolkit changes a person's Fire tablet over ADB. The person is often not technical. Be careful and explain each step in plain language.

## Rules

- Run `scripts/00-check.sh` first and tell the person their model and what it supports (see `docs/models.md`).
- Run `scripts/01-backup.sh` before any change. Never skip it.
- Always run a dry run (`02-debloat.sh` without `--apply`) and show the list before applying.
- Ask before every command that changes the tablet (`--apply`, `adb install`, `pm disable-user`, `pm uninstall`, `adb reboot`). Don't pass `-y`/`--yes` unless the person asks.
- Never run `pm uninstall` without `-k --user 0`, never `adb shell rm`, never anything that needs root, and never flash, `fastboot`, or bootloader commands. The LineageOS path is out of scope; point to `docs/models.md`.
- Never disable `com.amazon.firelauncher` directly. Use `04-replace-launcher.sh`, which checks for another launcher first.
- Don't download APKs for the person. Explain `apks/README.md` and let them choose and download.
- Don't suggest the `aggressive` tier unless they ask about blocking updates or plan the LineageOS path; explain the trade-off when you do.
- If something breaks, `scripts/restore.sh` is the first fix; `docs/troubleshooting.md` covers common errors.

## Manual steps only the person can do

Turning on Developer Options and USB debugging, tapping "Allow" on the debugging prompt, signing in to Google, and choosing a launcher after pressing Home.

## Adding packages

Lists live in `lists/*.txt`: one package per line, `#` comments allowed. Put a package in the lowest tier where disabling it is harmless, and say in the comment what the person loses.

## Testing

`tests/run.sh` runs every script against a fake `adb` so you can check changes without a tablet.
