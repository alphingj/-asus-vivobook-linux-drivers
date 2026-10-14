# E1404FA Linux Pack — Vivobook Go 14 (Go 14)

Driver/plugin notes + one-command Linux setup for the **ASUS Vivobook Go
E1404FA** (board `E1404FA`, Ryzen 5 7520U, PixArt `ASUP1411` touchpad with
NumberPad). Goal: working touchpad NumberPad + backlight, fan profiles,
and corner LED on Linux — without redistributing ASUS binaries.

> All IDs below were read from the author's own unit (Windows 11, BIOS
> `E1404FA.318`). No `.sys`/`.exe`/`.dll`/`.inf` files are included.

## One-command install (Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/install.sh | bash
```

Replace `<you>/<repo>` with this repo's path. What it does: installs deps
(`i2c-tools`, python3, libevdev), enables `i2c-dev`, finds the touchpad bus
(expects `0x15`), adds you to `i2c,input,uinput`, installs upstream
`asus-numberpad-driver` with an E1404FA preset, and prints a read-only
fan/thermal report. Options:

```bash
./install.sh --check-only   # detect only, change nothing (start here)
./install.sh --numpad       # NumberPad only
./install.sh --fan          # fan/thermal report only
./install.sh --led-test     # interactive backlight/LED sweep (asks first)
./install.sh --bus 0 --addr 15 --yes
```

From a clone: `git clone https://github.com/<you>/<repo>.git && cd <repo> && ./install.sh`.

## Status

| Feature | Windows 11 | Linux after this pack |
|---|---|---|
| NumberPad grid + toggle | Yes | Yes via upstream driver + E1404FA preset (`numpad/`) |
| Grid backlight levels | Yes | `0x41`-`0x48` family first, sweep in `--led-test` |
| Fan Silent/Balanced/Turbo (Fn+F5) | Yes | `fan_boost_mode` / `throttle_thermal_policy` or `asusctl` (`fan/`) |
| Corner NumLock LED | Yes | Unverified — known `ASUP14xx` issue class (`touchpad-led/`) |
| Temps/sensors | MyASUS | `sensors` (`k10temp`, `amdgpu`) |

## Tested models

Windows-side IDs are verified on the author's unit; Linux columns need
test reports (see `CONTRIBUTING.md`). The installer auto-detects the
`ASUP`/`ASUE`/`ASUF`/`ELAN` families — E1404FA values are just defaults.

| Model | Touchpad | Addr | NumberPad | Backlight | Fan | Corner LED |
|---|---|---|---|---|---|---|
| Vivobook Go 14 E1404FA (author) | `ASUP1411` / `093A` | `0x15` | Expected via upstream | `0x41`-`0x48` family, untested | IDs documented, untested | Unknown |
| Your Vivobook here | ? | ? | ? | ? | ? | ? |

## Layout

```text
install.sh           one-command Linux setup (this file's installer)
tools/               Dump-E1404FA.ps1 (Windows inventory), Probe-AsusWMI.ps1
                     (read-only WMI probe), linux/numpad-test.sh (manual sweep)
numpad/              I2C protocol, layouts, Linux port notes
fan/                 WMI IDs, registry knobs, Linux mapping
touchpad-led/        backlight vs corner LED, test protocol
firmware/            ACPI/DSDT notes (ETPD, WMNB, _CRS 0x15)
docs/                HARDWARE, WINDOWS-DRIVERS, ARCHITECTURE (diagrams),
                     USER_GUIDE (30-min walkthrough), TROUBLESHOOTING
CONTRIBUTING.md      what to report per revision
```

## Manual path (no script)

Follow `docs/USER_GUIDE.md` (7 steps, ~30 min). Background per feature:

1. `docs/HARDWARE.md` — confirm your unit matches (`ASUP1411`, `VID_093A`, `ASUS2018`).
2. `numpad/README.md` — bus/addr check, layout pick, config keys.
3. `fan/README.md` — read `DSTS` for `0x00110019`/`0x00110018`/`0x00120075` first; write one mode only with temps watched.
4. `touchpad-led/README.md` — backlight vs LED are different paths; test separately.
5. `firmware/ACPI.md` — dump your DSDT from a live USB for the ETPD/WMNB blocks.

## Safety

- One variable at a time; keep UEFI defaults as the way back.
- Never run `DEVS` (fan writes) or raw I2C writes blind — the scripts always
  confirm IDs first and ask before touching hardware.
- Dual-boot Windows if you can: prove each feature there, note the exact
  toggle, then reproduce on Linux.

## FAQ

**Which bus/address?** `i2c-N` from the touchpad block of
`/proc/bus/input/devices`, address `0x15` (`0x38` only for
`ASUF1416/1205/1204`). `--check-only` prints both.

**Keys work but no light?** Wrong brightness set — run `--led-test`.

**Grid lights but corner LED dark?** Separate path; see `touchpad-led/`
and report your value table.

**No `asus` platform device?** `asus-wmi` did not bind — check
`dmesg | grep -i asus`, try a newer kernel, then `asusctl`.

**Does this replace MyASUS?** No — it reimplements the three hardware
features above. Battery-health charging and Splendid are out of scope.

## Contributing

PRs with per-revision findings welcome: touchpad `VID:PID`, bus/addr,
working brightness set, `DSTS` hex per fan ID, kernel version. Scrub
serials and DSDT personalization before posting. Rules: `CONTRIBUTING.md`;
stuck? `docs/TROUBLESHOOTING.md`. See `numpad/`,
`fan/`, `touchpad-led/` for what to capture.

## Credits

- `asus-linux-drivers/asus-numberpad-driver` (I2C protocol, layouts)
- Linux `drivers/platform/x86/asus-wmi.c` (WMI IDs)
- `asus-linux-org/asusctl` + `supergfxctl` (profiles)

MIT — see `LICENSE`. ASUS marks belong to their owners.
