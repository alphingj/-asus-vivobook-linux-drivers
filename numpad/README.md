# NumberPad on the E1404FA touchpad

## What it is

Illuminated numeric grid printed on the precision touchpad (`ASUP1411`,
PixArt `VID_093A`, I2C HID). Windows toggles it by holding/tapping the
top-right icon (~1 s) or sliding from a corner; top-left slide opens the
calculator (`FindCalculator.exe`). The filter driver
(`AsusNUMPADFilter.sys`) owns grid geometry/timing; `AsusNumPadService`
owns the HID Col05 vendor channel and LED state.

## Verified IDs (author machine)

- ACPI: `ACPI\ASUP1411`, compat `PNP0C50`, service `hidi2c`
- HID cols: mouse `Col01`, touchpad `Col02`, input-config `Col03`, keyboard
  `Col04`, **vendor `Col05` (`FF00:0001`)** = control channel
- Silicon: `VID_093A` (PixArt). Linux should show `ASUP1411:00 093A:xxxx`
  Touchpad on some `i2c-N` bus (`AMDI0010` controller on this AMD board).
- I2C address: `0x15` expected (upstream default; `0x38` only for
  `ASUF1416/ASUF1205/ASUF1204` class). **Verify with the check script
  before writing anything.**

## I2C protocol (from upstream `asus-numberpad-driver`, compatible frame)

13-byte write to the touchpad I2C address:

```text
05 00 3d 03 06 00 07 00 0d 14 03 <VAL> ad
```

via e.g. `i2ctransfer -f -y <bus> w13@0x15 …`. Known `<VAL>` family:

| VAL | Meaning (upstream) |
|---|---|
| `0x00` | deactivate / backlight off |
| `0x01` | activate grid |
| `0x60` | unlock/backlight enable companion to `0x01` |
| `0x41`–`0x48` (also `0x20`–`0x2f` on some layouts) | brightness levels |

The exact brightness set + activation pair for *your* panel must be found
with `install_device_check.sh` (`send_test_activation`/`send_test_deactivation`)
while watching the pad. E1404FA is expected in the `0x41`–`0x48` family but
treat that as a hypothesis until tested.

## Linux port path

1. Use upstream `asus-linux-drivers/asus-numberpad-driver` (Python, libevdev
   + `i2c-tools`, optional `hidraw` backlight path in newer releases).
2. Install deps, add user to `i2c,input,uinput`, run
   `install_device_check.sh` to confirm bus (`i2c-N`) + addr (`0x15`).
3. Pick the layout whose printed grid matches the E1404FA pad (5-col grid;
   compare `% =`, NumLock-corner, left/right icons against `layouts/*.py`).
   If none matches, file an upstream issue with photos + `DSDT.dsl` ETPD
   block + `/proc/bus/input/devices` touchpad block.
4. Key tunables (config `numberpad_dev`): `activation_time`,
   `top_right_icon_*`, `top_left_icon_*` (calculator/brightness),
   `backlight_levels`, `default_backlight_level`, `disable_due_inactivity_time`,
   idle (`idle_time`/`idle_brightness`) + external-keyboard udev rule.

## INF hints for layout authors

`AsusNUMPADFilter.inf` carries per-geometry tables you can crib dimensions
from: `NUMPADLAYOUT_*` (incl. `NHXL/NHL/NHM/NHS`, `…LNDZ`, `GH…`, `CH…`,
`NVM/GVL/GVM` variants), `NUMPAD_00..10` timings, `NUMPADGESTURE_*`,
`COSUMR_*` + `COSUMRLAYOUT_*`. Offsets are in 0.1 mm. Do not copy the INF
wholesale; read your own copy and translate the one geometry that matches
the E1404FA pad.

## Troubleshooting

- “No i2c interface”: missing `i2c-tools`/kernel `i2c-dev`, or wrong bus —
  re-read the touchpad block in `/proc/bus/input/devices`.
- Lights but no keys: layout mismatch (grid math wrong) — try neighboring
  5-col layouts.
- Keys but no lights: brightness-set mismatch — sweep `0x41`–`0x48` then
  `0x20`–`0x2f` with `0x01`+`0x60` latched (see `tools/linux/numpad-test.sh`).
- NumLock corner LED dead while grid lights: separate LED path — see
  `touchpad-led/README.md` (known `ASUP14xx` issue class).
