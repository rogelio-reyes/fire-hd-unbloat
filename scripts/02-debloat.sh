#!/usr/bin/env bash
# Step 2: disable Amazon apps for the current user. Reversible with restore.sh.
#
# Usage:
#   ./scripts/02-debloat.sh                          # dry run, "safe" list
#   ./scripts/02-debloat.sh --tier recommended       # dry run, safe + recommended
#   ./scripts/02-debloat.sh --tier recommended --apply
#
# Tiers are cumulative: safe < recommended < aggressive.
# Nothing is deleted. Each package is disabled with `pm disable-user`; if Fire OS
# refuses that, it falls back to `pm uninstall -k --user 0`, which hides the app
# for this user but keeps it on the system partition (restore.sh brings it back).
source "$(dirname "$0")/lib.sh"

tier="safe"
apply=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)  tier="${2:-}"; shift 2 ;;
    --apply) apply=1; shift ;;
    -y|--yes) export ASSUME_YES=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

case "$tier" in
  safe)        files=(safe) ;;
  recommended) files=(safe recommended) ;;
  aggressive)  files=(safe recommended aggressive) ;;
  *) die "Tier must be safe, recommended or aggressive." ;;
esac

require_device

if [[ ! -e "$BACKUPS_DIR/latest-${ANDROID_SERIAL}" ]]; then
  die "No backup found for this tablet. Run ./scripts/01-backup.sh first."
fi

log="$BACKUPS_DIR/latest-${ANDROID_SERIAL}/changes.log"
installed="$(dsh pm list packages -u | sed 's/^package://')"

todo=()
for f in "${files[@]}"; do
  while IFS= read -r pkg; do
    if printf '%s\n' "$installed" | grep -qx "$pkg"; then
      todo+=("$pkg")
    fi
  done < <(read_list "$LISTS_DIR/$f.txt")
done

if [[ ${#todo[@]} -eq 0 ]]; then
  ok "None of the packages in the '$tier' tier are present. Nothing to do."
  exit 0
fi

info "Tier '$tier': ${#todo[@]} matching packages on this tablet:"
for p in "${todo[@]}"; do echo "    $p"; done
echo

if [[ $apply -eq 0 ]]; then
  info "Dry run only. Re-run with --apply to make these changes."
  exit 0
fi

# Never disable the launcher here; 04-replace-launcher.sh handles it safely.
for p in "${todo[@]}"; do
  [[ "$p" == "com.amazon.firelauncher" ]] && die "Launcher must not be in a debloat list. Use 04-replace-launcher.sh."
done

confirm "Disable these ${#todo[@]} packages?" || die "Cancelled."

failed=0
for p in "${todo[@]}"; do
  if out="$(dsh pm disable-user --user 0 "$p" 2>&1)" && [[ "$out" == *"disabled"* ]]; then
    ok "disabled  $p"
    echo "disabled $p" >> "$log"
  elif out2="$(dsh pm uninstall -k --user 0 "$p" 2>&1)" && [[ "$out2" == *"Success"* ]]; then
    ok "hidden    $p   (disable was blocked; hidden for user 0 instead)"
    echo "hidden $p" >> "$log"
  else
    warn "skipped   $p   ($out ${out2:-})"
    failed=$((failed + 1))
  fi
done

echo
[[ $failed -gt 0 ]] && warn "$failed package(s) could not be changed. Fire OS protects some apps; that is normal."
ok "Done. Restart the tablet to see the full effect: adb reboot"
info "Undo anytime with ./scripts/restore.sh"
