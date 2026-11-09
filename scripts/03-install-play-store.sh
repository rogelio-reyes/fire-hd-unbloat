#!/usr/bin/env bash
# Step 3: install the Google Play Store from APKs you downloaded into ./apks/
#
# Google's apps can't be redistributed, so this repo doesn't include them.
# See apks/README.md for which files to download and how to pick versions.
# The script finds them by package name in the filename and installs them in
# the order Google's services require.
#
# Plain .apk files are preferred. If a step has no .apk but has a bundle
# (.apkm, .xapk or .apks, which are zip files of several APKs), the script
# unpacks it to a temporary folder and installs the base app plus the pieces
# that match this tablet's CPU and language with `adb install-multiple`.
source "$(dirname "$0")/lib.sh"
require_device

shopt -s nullglob nocaseglob
all=("$APKS_DIR"/*.apk)
bundles=("$APKS_DIR"/*.apkm "$APKS_DIR"/*.xapk "$APKS_DIR"/*.apks)
shopt -u nocaseglob

if [[ ${#all[@]} -eq 0 && ${#bundles[@]} -eq 0 ]]; then
  die "No .apk or .apkm files in apks/. See apks/README.md."
fi

find_in() {
  # find_in <regex> <file>...  -> first file whose name matches
  local re="$1" f; shift
  for f in "$@"; do
    if [[ "$(basename "$f" | tr '[:upper:]' '[:lower:]')" =~ $re ]]; then
      echo "$f"; return 0
    fi
  done
  return 1
}

find_apk() {
  # Prefer a plain .apk; fall back to a bundle.
  if [[ ${#all[@]} -gt 0 ]] && find_in "$1" "${all[@]}"; then return 0; fi
  if [[ ${#bundles[@]} -gt 0 ]] && find_in "$1" "${bundles[@]}"; then return 0; fi
  return 1
}

is_bundle() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *.apkm|*.xapk|*.apks) return 0 ;;
    *) return 1 ;;
  esac
}

tmpdirs=()
cleanup() {
  local d
  if [[ ${#tmpdirs[@]} -gt 0 ]]; then
    for d in "${tmpdirs[@]}"; do rm -rf "$d"; done
  fi
}
trap cleanup EXIT

install_bundle() {
  # install_bundle <bundle file> <package name>
  local bundle="$1" pkg="$2" dir abi lang base f
  command -v unzip >/dev/null 2>&1 || die "unzip not found; it is needed to open $(basename "$bundle")."
  dir="$(mktemp -d)"
  tmpdirs+=("$dir")
  unzip -q -o "$bundle" -d "$dir" || die "Could not open $(basename "$bundle"). Is the download complete?"

  # .apkm and .apks use base.apk; .xapk usually names it after the package.
  if [[ -f "$dir/base.apk" ]]; then base="$dir/base.apk"
  elif [[ -f "$dir/$pkg.apk" ]]; then base="$dir/$pkg.apk"
  else die "No base.apk inside $(basename "$bundle")."; fi

  # Split names use underscores: armeabi-v7a -> armeabi_v7a.
  abi="$(prop ro.product.cpu.abi 2>/dev/null | tr '-' '_' || true)"
  lang="$(prop persist.sys.locale 2>/dev/null || true)"
  [[ -z "$lang" ]] && lang="$(prop ro.product.locale 2>/dev/null || true)"
  lang="$(printf '%s' "${lang:-en}" | sed 's/[-_].*//' | tr '[:upper:]' '[:lower:]')"
  [[ -z "$lang" ]] && lang="en"

  local parts=("$base")
  for f in "$dir/split_config.$abi.apk" "$dir/config.$abi.apk" \
           "$dir/split_config.$lang.apk" "$dir/config.$lang.apk"; do
    [[ -f "$f" ]] && parts+=("$f")
  done
  # If the tablet's language has no split, fall back to English.
  if [[ ! -f "$dir/split_config.$lang.apk" && ! -f "$dir/config.$lang.apk" ]]; then
    for f in "$dir/split_config.en.apk" "$dir/config.en.apk"; do
      [[ -f "$f" ]] && parts+=("$f")
    done
  fi
  [[ -n "$abi" && ! -f "$dir/split_config.$abi.apk" && ! -f "$dir/config.$abi.apk" ]] \
    && info "No $abi piece in this bundle; installing without one (fine for universal bundles)."

  info "Bundle pieces: $(for f in "${parts[@]}"; do printf '%s ' "$(basename "$f")"; done)"
  adb install-multiple -r "${parts[@]}"
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
    plan+=("$name|$pkg|$f")
  elif [[ "$need" == "required" ]]; then
    die "Missing $name file in apks/ (filename should start with $pkg)."
  else
    info "No $name file found; that's fine on Fire OS 7 and newer."
  fi
done

info "CPU ABI on this tablet: $(prop ro.product.cpu.abi). Your files should match it."
info "Install order:"
for p in "${plan[@]}"; do
  rest="${p#*|}"; file="${rest#*|}"
  kind=""; is_bundle "$file" && kind="  (bundle)"
  echo "    ${p%%|*}: $(basename "$file")$kind"
done
echo
confirm "Install these now?" || die "Cancelled."

for p in "${plan[@]}"; do
  name="${p%%|*}"; rest="${p#*|}"; pkg="${rest%%|*}"; file="${rest#*|}"
  info "Installing $name..."
  if is_bundle "$file"; then
    if install_bundle "$file" "$pkg"; then ok "$name installed"; else die "$name failed. Check the version and ABI match your Fire OS."; fi
  elif adb install -r "$file"; then
    ok "$name installed"
  else
    die "$name failed. Check the version and ABI match your Fire OS."
  fi
done

ok "Done. Reboot (adb reboot), open Play Store and sign in."
info "If Play Store crashes on open, wait 5 minutes after reboot and try again."
