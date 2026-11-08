#!/usr/bin/env bash
# Shared helpers for fire-hd-unbloat. Sourced by every script; not run directly.

set -euo pipefail

# shellcheck disable=SC2034  # used by the scripts that source this file
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
LISTS_DIR="$REPO_ROOT/lists"
# shellcheck disable=SC2034
BACKUPS_DIR="$REPO_ROOT/backups"
# shellcheck disable=SC2034
APKS_DIR="$REPO_ROOT/apks"

if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_BLU=$'\033[34m'; C_OFF=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_OFF=""
fi

info()  { printf '%s[i]%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()    { printf '%s[ok]%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn()  { printf '%s[!]%s %s\n' "$C_YEL" "$C_OFF" "$*" >&2; }
die()   { printf '%s[x]%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

confirm() {
  # confirm "Question?"  -> returns 0 on yes. Respects ASSUME_YES=1.
  [[ "${ASSUME_YES:-0}" == "1" ]] && return 0
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

require_adb() {
  if ! command -v adb >/dev/null 2>&1; then
    die "adb not found. On a Mac: brew install android-platform-tools"
  fi
}

# Ensure exactly one authorized device is connected; export its serial.
require_device() {
  require_adb
  local lines serials unauthorized
  lines="$(adb devices | tail -n +2 | sed '/^[[:space:]]*$/d')"
  unauthorized="$(printf '%s\n' "$lines" | awk '$2=="unauthorized"{print $1}')"
  if [[ -n "$unauthorized" ]]; then
    die "Tablet is connected but not authorized. Unlock it and tap 'Allow' on the USB debugging prompt, then re-run."
  fi
  serials="$(printf '%s\n' "$lines" | awk '$2=="device"{print $1}')"
  local count
  count="$(printf '%s\n' "$serials" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$count" == "0" ]]; then
    die "No tablet found. Check the USB cable (must be a data cable) and that USB debugging is on."
  elif [[ "$count" != "1" ]]; then
    die "More than one Android device connected. Unplug the others, or set ANDROID_SERIAL."
  fi
  export ANDROID_SERIAL="${ANDROID_SERIAL:-$serials}"
}

# Run a shell command on the device and strip Windows line endings.
dsh() { adb shell "$@" | tr -d '\r'; }

prop() { dsh getprop "$1"; }

# Map model codes to a friendly name and what is possible.
# Model codes come from Amazon / Wikipedia tables; PRs welcome for others.
describe_model() {
  case "$1" in
    KFGIWI) echo "Fire HD 8 (6th gen, 2016)|unlockable" ;;
    KFDOWI) echo "Fire HD 8 (7th gen, 2017)|unlockable" ;;
    KFKAWI) echo "Fire HD 8 (8th gen, 2018)|unlockable" ;;
    KFONWI) echo "Fire HD 8 / HD 8 Plus (10th gen, 2020)|locked" ;;
    *)      echo "Unknown or newer Fire tablet ($1)|unknown" ;;
  esac
}

# Is a package installed (for user 0, including disabled ones)?
pkg_installed() {
  dsh pm list packages -u 2>/dev/null | grep -qx "package:$1"
}

pkg_disabled() {
  dsh pm list packages -d 2>/dev/null | grep -qx "package:$1"
}

# Read a package list file: strip comments and blank lines.
read_list() {
  sed -e 's/#.*$//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$1"
}
