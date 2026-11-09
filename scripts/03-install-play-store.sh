#!/usr/bin/env bash
# Step 3: install the Google Play Store from APKs you downloaded into ./apks/
#
# Google's apps can't be redistributed, so this repo doesn't include them.
# See apks/README.md for which four files to download and how to pick versions.
# The script finds them by package name in the filename and installs them in
# the order Google's services require.
source "$(dirname "$0")/lib.sh"
require_device

shopt -s nullglob nocaseglob
all=("$APKS_DIR"/*.apk)
bundles=("$APKS_DIR"/*.apkm "$APKS_DIR"/*.xapk "$APKS_DIR"/*.apks)
shopt -u nocaseglob

if [[ ${#bundles[@]} -gt 0 ]]; then
  warn "Found bundle files (.apkm/.xapk/.apks). adb can't install these directly."
  warn "Download the plain .apk variant instead. Ignoring: ${bundles[*]##*/}"
fi
[[ ${#all[@]} -eq 0 ]] && die "No .apk files in apks/. See apks/README.md."

find_apk() {
  # find_apk <regex>  -> first file whose name matches
  local f
  for f in "${all[@]}"; do
    if [[ "$(basename "$f" | tr '[:upper:]' '[:lower:]')" =~ $1 ]]; then
      echo "$f"; return 0
    fi
  done
  return 1
}

# Order matters. gsf.login (Account Manager) only applies to older Fire OS.
steps=(
  "Google Account Manager|com\.google\.android\.gsf\.login|com.google.android.gsf.login|optional"
  "Google Services Framework|com\.google\.android\.gsf[_-]|com.google.android.gsf|required"
  "Google Play Services|com\.google\.android\.gms[_-]|com.google.android.gms|required"
  "Google Play Store|com\.(google\.)?android\.vending[_-]|com.android.vending|required"
)

plan=()
for s in "${steps[@]}"; do
  IFS='|' read -r name re pkg need <<<"$s"
  if f="$(find_apk "$re")"; then
    plan+=("$name|$f")
  elif [[ "$need" == "required" ]]; then
    die "Missing $name APK in apks/ (filename should start with $pkg)."
  else
    info "No $name APK found; that's fine on Fire OS 7 and newer."
  fi
done

info "CPU ABI on this tablet: $(prop ro.product.cpu.abi). Your APKs should match it."
info "Install order:"
for p in "${plan[@]}"; do echo "    ${p%%|*}: $(basename "${p#*|}")"; done
echo
confirm "Install these now?" || die "Cancelled."

for p in "${plan[@]}"; do
  name="${p%%|*}"; file="${p#*|}"
  info "Installing $name..."
  if adb install -r "$file"; then ok "$name installed"; else die "$name failed. Check the version and ABI match your Fire OS."; fi
done

ok "Done. Reboot (adb reboot), open Play Store and sign in."
info "If Play Store crashes on open, wait 5 minutes after reboot and try again."
