#!/usr/bin/env bash
# Step 4: make another launcher the home screen by disabling Amazon's.
#
# Usage:
#   ./scripts/04-replace-launcher.sh            # check only
#   ./scripts/04-replace-launcher.sh --apply    # disable Amazon's launcher
#   ./scripts/04-replace-launcher.sh --undo     # bring Amazon's launcher back
#
# Install a launcher first (for example from the Play Store after step 3).
# This script refuses to act unless another home screen app is installed, so
# the tablet can't end up with no home screen.
source "$(dirname "$0")/lib.sh"
require_device

AMZ="com.amazon.firelauncher"
mode="check"
case "${1:-}" in
  --apply) mode="apply" ;;
  --undo)  mode="undo" ;;
  "" )     ;;
  -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
  *) die "Unknown option: $1" ;;
esac

if [[ "$mode" == "undo" ]]; then
  dsh pm enable "$AMZ" >/dev/null 2>&1 || dsh cmd package install-existing "$AMZ" >/dev/null
  ok "Amazon launcher restored. Press the Home button."
  exit 0
fi

homes="$(dsh cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null \
  | grep '/' | sed 's#/.*##; s/^[[:space:]]*//' | sort -u || true)"

others="$(printf '%s\n' "$homes" | grep -v -x "$AMZ" | grep -v -E '^(com\.android\.settings|com\.amazon\.kindle\.otter\.oobe.*|com\.android\.provision)$' | sed '/^$/d' || true)"

if [[ -z "$homes" ]]; then
  die "Could not list home screen apps on this Fire OS version. Not changing anything."
fi
if [[ -z "$others" ]]; then
  die "No other launcher installed. Install one first (e.g. from the Play Store), then re-run."
fi

info "Other launchers found:"
# shellcheck disable=SC2086  # intentional word splitting, one package per line
printf '    %s\n' $others
[[ "$mode" == "check" ]] && { info "Run with --apply to switch."; exit 0; }

confirm "Disable Amazon's launcher so Home opens your new one?" || die "Cancelled."
if dsh pm disable-user --user 0 "$AMZ" 2>&1 | grep -q disabled; then
  log="$BACKUPS_DIR/latest-${ANDROID_SERIAL}/changes.log"
  [[ -d "$(dirname "$log")" ]] && echo "disabled $AMZ" >> "$log"
  ok "Done. Press Home and choose your launcher, then 'Always'."
  info "Undo: ./scripts/04-replace-launcher.sh --undo"
else
  warn "Fire OS blocked disabling the launcher on this version."
  warn "Pressing Home will still open Amazon's launcher. Open your new launcher"
  warn "from the app list instead. See docs/troubleshooting.md."
fi
