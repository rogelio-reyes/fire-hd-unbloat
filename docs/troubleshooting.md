# Troubleshooting

**`adb devices` shows nothing**
Use a data USB cable (many charging cables are power-only). Check that USB debugging is on. Try another USB port or a different adapter.

**Shows `unauthorized`**
Unlock the tablet screen. An "Allow USB debugging?" prompt should be waiting. Tick "Always allow from this computer" and tap Allow. If it never appears: `adb kill-server`, unplug, plug back in.

**Developer Options is missing**
Settings > Device Options > About Fire Tablet, tap **Serial Number** seven times.

**A package says "Shell cannot change component state"**
Fire OS protects it. The debloat script falls back to hiding it for your user. If both fail, it's skipped and nothing breaks.

**Play Store opens and immediately closes**
Reboot and wait a few minutes; Play Services needs to finish setting up. If it still fails, the Play Services APK probably doesn't match your Android version or CPU ABI. Uninstall it (`adb uninstall com.google.android.gms`) and try another variant.

**Something is broken and I want it back**
`./scripts/restore.sh` undoes everything recorded in your latest backup. `./scripts/restore.sh --all` re-enables every package this toolkit knows about. As a last resort, Settings > Device Options > Reset to Factory Defaults restores Fire OS completely.

**Home button shows a black screen**
`./scripts/04-replace-launcher.sh --undo` brings back Amazon's launcher.
