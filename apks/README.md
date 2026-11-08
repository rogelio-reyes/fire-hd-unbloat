# APKs go here

Google's apps can't be redistributed, so download these yourself from a source you trust (APKMirror is the usual one) and drop them in this folder. Files here are ignored by git.

| # | App | Package name (filename must contain it) | Needed? |
|---|-----|------------------------------------------|---------|
| 1 | Google Account Manager | `com.google.android.gsf.login` | Fire OS 5 only |
| 2 | Google Services Framework | `com.google.android.gsf` | Yes |
| 3 | Google Play Services | `com.google.android.gms` | Yes |
| 4 | Google Play Store | `com.google.android.vending` | Yes |

## Picking the right versions

1. Run `./scripts/00-check.sh` and note **Android base** and **CPU ABI**.
2. For Services Framework, pick the version for your Android base (Android 9 for Fire OS 7, Android 11 for Fire OS 8).
3. For Play Services, pick the variant whose architecture matches your CPU ABI, and whose minimum Android version is at or below yours. Don't pick a `-wear`, `-tv` or `-auto` variant.
4. Play Store: any recent version works; it updates itself.
5. Download plain `.apk` files. APKMirror's `.apkm` bundles can't be installed with adb.

Keep the default filenames (APKMirror's start with the package name), then run `./scripts/03-install-play-store.sh`.
