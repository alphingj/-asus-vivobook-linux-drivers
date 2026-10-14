# User guide — from zero to working NumberPad + fan

Assumes a Linux install on the E1404FA and 30 minutes. Run from the repo
root or via the one-liner in `../README.md`.

## 0. Confirm the unit matches

```bash
grep -i -A2 touchpad /proc/bus/input/devices | grep -i -E 'ASUP|ASUE|ASUF|ELAN|093A|04F3'
```

Expect an `ASU*`/`ELAN` name; `ASUP1411` + `093A` is the tested E1404FA
combo. Other families work via auto-detection — report yours
(see `../CONTRIBUTING.md`).

## 1. Detect only

```bash
./install.sh --check-only
```

Note the reported `bus=i2c-N addr=0x15`. No changes made.

## 2. Deps + groups

```bash
./install.sh --numpad
```

Re-login afterwards (group membership needs it), then confirm:

```bash
ls /dev/i2c-*
```

## 3. Test the toggle

Hold the top-right pad icon ~1s. The grid should light and the keys type
`789/uiop/jkl;/m,.` rows. If keys are offset, re-run the upstream
installer and pick the next 5-column layout (`../numpad/README.md`).

## 4. Backlight

If keys work but stay dark:

```bash
./install.sh --led-test
```

Answer `y` only for the value that lights the grid. First candidates:
`0x01` + `0x60`, then `0x41`-`0x48`.

## 5. Fan

```bash
./install.sh --fan
```

Compare `fan_boost_mode` / `throttle_thermal_policy` against
`../fan/README.md`, and cross-check temps with `sensors`. Switch profiles
with `asusctl` if installed; otherwise the sysfs files are the API.

## 6. Corner LED

Separate from step 4. Follow `../touchpad-led/README.md` and record your
value table — a "grid yes, LED no" result is itself a useful report.

## 7. Report back

Post bus/addr, working brightness set, layout name, `DSTS` hex per fan
ID, and kernel version per `../CONTRIBUTING.md`.
