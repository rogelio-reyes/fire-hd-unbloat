#!/usr/bin/env bash
# Runs every script against tests/fake-adb. No tablet needed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin"
cp "$here/fake-adb" "$work/bin/adb"; chmod +x "$work/bin/adb"
export PATH="$work/bin:$PATH" FAKE_ADB_STATE="$work/state" ASSUME_YES=1

# Run against a copy so real backups/ and apks/ are untouched.
cp -R "$root/scripts" "$root/lists" "$work/"; mkdir -p "$work/apks"
cd "$work"

pass=0; fail=0
check() { if eval "$2"; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }
S="$FAKE_ADB_STATE"

./scripts/00-check.sh > out.txt 2>&1
check "check identifies 2020 model" 'grep -q "10th gen, 2020" out.txt'

check "debloat refuses without backup" '! ./scripts/02-debloat.sh >/dev/null 2>&1'

./scripts/01-backup.sh > out.txt 2>&1
check "backup writes package list" 'ls backups/*/all-packages.txt >/dev/null'

./scripts/02-debloat.sh > out.txt 2>&1
check "dry run changes nothing" '[[ ! -s "$S/disabled" ]]'
check "dry run lists only present packages" 'grep -q com.amazon.avod out.txt && ! grep -q com.amazon.mp3 out.txt'

./scripts/02-debloat.sh --tier aggressive --apply > out.txt 2>&1
check "apply disables Prime Video" 'grep -qx com.amazon.avod "$S/disabled"'
check "blocked package falls back to hide" 'grep -qx com.amazon.device.software.ota "$S/hidden"'
check "launcher never disabled by debloat" '! grep -qx com.amazon.firelauncher "$S/disabled"'

check "launcher swap refused without another launcher" '! ./scripts/04-replace-launcher.sh --apply >/dev/null 2>&1'
touch "$S/has-launcher"
./scripts/04-replace-launcher.sh --apply > out.txt 2>&1
check "launcher swap works with another launcher" 'grep -qx com.amazon.firelauncher "$S/disabled"'

check "play store refuses with no APKs" '! ./scripts/03-install-play-store.sh >/dev/null 2>&1'
for f in com.google.android.gsf_11.apk com.google.android.gms_24.apk com.google.android.vending_42.apk; do touch "apks/$f"; done
./scripts/03-install-play-store.sh > out.txt 2>&1
check "play store installs in order" '[[ "$(tr "\n" " " < "$S/installed-apks")" == "com.google.android.gsf_11.apk com.google.android.gms_24.apk com.google.android.vending_42.apk " ]]'

./scripts/restore.sh > out.txt 2>&1
check "restore re-enables disabled apps" '[[ ! -s "$S/disabled" ]]'
check "restore brings back hidden apps" '[[ ! -s "$S/hidden" ]]'

echo; echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
