#!/usr/bin/env bash
# Step 0: check your Mac's tools and identify the connected tablet.
# Read-only. Changes nothing on the tablet.
source "$(dirname "$0")/lib.sh"

info "Checking for adb..."
require_adb
ok "adb: $(adb version | head -1)"

info "Looking for the tablet..."
require_device
ok "Connected: $ANDROID_SERIAL"

model="$(prop ro.product.model)"
fireos="$(prop ro.build.version.name)"
android="$(prop ro.build.version.release)"
abi="$(prop ro.product.cpu.abi)"
IFS='|' read -r friendly status <<<"$(describe_model "$model")"

echo
echo "  Model:        $friendly"
echo "  Model code:   $model"
echo "  Fire OS:      ${fireos:-unknown}"
echo "  Android base: $android"
echo "  CPU ABI:      $abi   (pick APKs that match this)"
echo

case "$status" in
  unlockable)
    warn "This generation CAN have its bootloader unlocked and run LineageOS,"
    warn "but that is an advanced, Linux-only process with a real risk of bricking."
    warn "See docs/models.md. If you want that path later, avoid Fire OS updates:"
    warn "newer updates can patch the exploit."
    ;;
  locked)
    info "No known bootloader unlock for this generation. The debloat path"
    info "(scripts 01-04) is the way to get a near-stock Android experience."
    ;;
  *)
    info "Model not in our table. The debloat scripts only touch packages that"
    info "actually exist, so they should still work. Please open an issue with"
    info "your model code so we can add it."
    ;;
esac

echo
info "Next: ./scripts/01-backup.sh"
