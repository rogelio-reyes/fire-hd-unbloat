#!/usr/bin/env bash
# Undo: re-enable everything this toolkit changed.
#
# Usage:
#   ./scripts/restore.sh          # undo changes recorded in the latest backup's changes.log
#   ./scripts/restore.sh --all    # re-enable every package in every list (no log needed)
source "$(dirname "$0")/lib.sh"
require_device

pkgs=()
if [[ "${1:-}" == "--all" ]]; then
  while IFS= read -r p; do pkgs+=("$p"); done < <(cat "$LISTS_DIR"/*.txt | sed -e 's/#.*$//' -e 's/[[:space:]]*$//' -e '/^$/d' | sort -u)
  pkgs+=("com.amazon.firelauncher")
else
  log="$BACKUPS_DIR/latest-${ANDROID_SERIAL}/changes.log"
  [[ -f "$log" ]] || die "No changes.log for this tablet. Use --all to re-enable everything in the lists."
  while IFS= read -r line; do pkgs+=("${line#* }"); done < <(sort -u "$log")
fi

[[ ${#pkgs[@]} -eq 0 ]] && { ok "Nothing recorded to restore."; exit 0; }
info "Restoring ${#pkgs[@]} package(s)."
confirm "Continue?" || die "Cancelled."

for p in "${pkgs[@]}"; do
  # Un-hide first (no-op if the app was only disabled), then re-enable.
  unhid=0
  if dsh cmd package install-existing "$p" 2>/dev/null | grep -qi "installed for user"; then unhid=1; fi
  if dsh pm enable "$p" 2>/dev/null | grep -q enabled || [[ $unhid -eq 1 ]]; then
    ok "restored  $p"
  else
    info "skipped   $p (not present on this tablet)"
  fi
done

ok "Done. Reboot to finish: adb reboot"
