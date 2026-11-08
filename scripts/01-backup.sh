#!/usr/bin/env bash
# Step 1: record the tablet's current package state so everything can be undone.
# Read-only on the tablet. Writes to ./backups/<serial>-<timestamp>/
source "$(dirname "$0")/lib.sh"
require_device

stamp="$(date +%Y%m%d-%H%M%S)"
dir="$BACKUPS_DIR/${ANDROID_SERIAL}-${stamp}"
mkdir -p "$dir"

dsh pm list packages -u | sed 's/^package://' | sort > "$dir/all-packages.txt"
dsh pm list packages -e | sed 's/^package://' | sort > "$dir/enabled.txt"
dsh pm list packages -d | sed 's/^package://' | sort > "$dir/disabled.txt"
dsh pm list packages    | sed 's/^package://' | sort > "$dir/installed-for-user.txt"
{
  echo "model=$(prop ro.product.model)"
  echo "fireos=$(prop ro.build.version.name)"
  echo "android=$(prop ro.build.version.release)"
  echo "abi=$(prop ro.product.cpu.abi)"
  echo "date=$stamp"
} > "$dir/device.txt"

# Point "latest" at this backup for the other scripts.
ln -sfn "$(basename "$dir")" "$BACKUPS_DIR/latest-${ANDROID_SERIAL}"

ok "Backup saved to backups/$(basename "$dir")"
info "$(wc -l < "$dir/all-packages.txt" | tr -d ' ') packages recorded."
info "Next: ./scripts/02-debloat.sh            (dry run, shows what would change)"
