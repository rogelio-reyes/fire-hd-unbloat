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

**Fire OS won't let me disable some apps or the launcher**
On Fire OS 7.3.3.1 (Fire HD 8, 2020) these packages are protected. Both `pm disable-user` ("Cannot disable a protected package") and the hide fallback `pm uninstall -k --user 0` (`DELETE_FAILED_INTERNAL_ERROR`) are refused, and getting past that needs root:

- lock screen ads: `com.amazon.kindle.kso`
- Help app: `com.amazon.csapp`
- Amazon Appstore: `com.amazon.venezia`
- Fire OS update service: `com.amazon.device.software.ota`, `.ota.override`, `com.amazon.kindle.otter.oobe.forced.ota`
- Amazon's launcher: `com.amazon.firelauncher`

The scripts report these as skipped and change nothing. So on this model the `aggressive` tier does not block Fire OS updates and does not remove the Appstore; it only adds what `recommended` adds (Alexa, Silk, Kindle, Kids). Install another browser (for example Firefox) before disabling Silk.

**Home still opens Amazon's launcher after installing another one**
Fire OS 7 has no "default home app" setting. We also tried `cmd package set-home-activity`, two reboots and hiding the launcher with `pm uninstall -k --user 0`; Home still went to Amazon's launcher. Open your launcher (for example Nova) from the app list instead. Replacing the home screen completely would need root, which this toolkit doesn't use.

**My download is a `.apkm` bundle**
`03-install-play-store.sh` handles `.apkm`, `.xapk` and `.apks` bundles: it unzips one to a temporary folder and runs `adb install-multiple` with the base app, the piece for your CPU (for example `armeabi_v7a`) and your language (English if there is none). If it fails, download a plain `.apk` instead. Whatever the format, pick a version whose `minAPI` is at or below your Android version (API 28 for Android 9).
