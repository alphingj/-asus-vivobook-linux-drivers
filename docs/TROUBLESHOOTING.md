# Troubleshooting — E1404FA

Find your symptom, apply the fix, follow the link for background.

| Symptom | Likely cause | Fix |
|---|---|---|
| `--check-only` finds no ASUS touchpad | Wrong machine/revision, or `libevdev` input layer missing | Re-check `HARDWARE.md` IDs; file per `../CONTRIBUTING.md` |
| No `/dev/i2c-*` nodes | `i2c-dev` not loaded | `sudo modprobe i2c-dev`; re-run installer |
| `i2ctransfer` fails on the detected bus | Wrong bus or addr | Re-read the touchpad block in `/proc/bus/input/devices`; try `--bus N`; addr is `0x15` except `ASUF1416/1205/1204` (`0x38`) |
| Permission denied on `/dev/i2c-*` | Groups not applied | Re-login after install; `id -nG` must show `i2c input uinput` |
| Grid toggles, keys are offset/wrong | Layout mismatch (5-col geometry differs) | Re-run upstream install, pick next 5-col layout (`../numpad/README.md`) |
| Keys work, no backlight | Wrong brightness set | `./install.sh --led-test`; sweep `0x41`-`0x48` then `0x20`-`0x2f` |
| Grid lights, corner LED dark | Separate LED path (known `ASUP14xx` class) | `../touchpad-led/README.md` protocol; report the table |
| No `/sys/devices/platform/asus*` | `asus-wmi` did not bind | `dmesg \| grep -i asus`; try a newer kernel; then `asusctl` |
| `DSTS` probe times out (Windows) | ATK WMI busy/hung | `../tools/Probe-AsusWMI.ps1` already caps at 15 s; treat as no-data, reboot, retry one ID |
| Upstream NumberPad install fails on deps | Distro not covered | Install `i2c-tools python3 libevdev curl` manually, re-run |

Still stuck: open an issue with the `../CONTRIBUTING.md` bundle (bus/addr,
touchpad block, kernel, what you tried). Partial data beats no data.
