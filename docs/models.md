# Which Fire HD 8 do I have, and what can it do?

Find it on the tablet: **Settings > Device Options > About Fire Tablet**, or run `./scripts/00-check.sh`.

| Generation | Year | Model code | Fire OS | Full Android (LineageOS)? | This toolkit |
|---|---|---|---|---|---|
| 6th | 2016 | KFGIWI | 5 | Yes, after bootloader unlock | Yes |
| 7th | 2017 | KFDOWI | 5 | Yes, after bootloader unlock | Yes |
| 8th | 2018 | KFKAWI | 6 / 7 | Yes, after bootloader unlock | Yes |
| 10th | 2020 | KFONWI | 7 | No known unlock | Yes (tested on 7.3.3.1) |
| 12th | 2022 / 2024 | varies | 8 | No known unlock | Yes (lightly tested) |

Corrections welcome. Please open an issue with your model code and Fire OS version.

## Two paths

**Debloat (this toolkit, every model).** Fire OS stays, but Amazon's apps and ads are disabled, the Play Store is installed and a normal launcher replaces Amazon's home screen. Fully reversible, no risk of bricking, works from a Mac.

**Replace Fire OS (2016-2018 models only).** Unlock the bootloader with a MediaTek exploit, install TWRP recovery, then flash an unofficial LineageOS build. You get real Android, but an old version, and you can brick the tablet. The exploit scripts are written for Linux; Apple Silicon Macs can't run them reliably, so use a Linux PC or a Linux live USB on an Intel machine.

This toolkit doesn't automate the second path. Start from the XDA Developers threads for your device:

- 2016 / 2017 (giza, douglas): search XDA for "Unlock / Root / TWRP / Unbrick Fire HD 8 2017 douglas" and "Lineage 14.1 douglas giza"
- 2018 (karnak): search XDA for "Fire HD 8 2018 karnak unlock TWRP"

Read the whole thread and the latest replies before starting. Fire OS versions newer than the ones listed in a thread may have patched the exploit.
