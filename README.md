# E1404FA Reverse Engineering Pack — Vivobook Go 14 (Go 14)

Reverse-engineered driver/plugin notes for the **ASUS Vivobook Go E1404FA
(Vivobook Go 14, board `E1404FA`)** so owners can reimplement CPU-fan,
touchpad-NumberPad, and touchpad-LED support — especially on Linux —
without redistributing ASUS binaries.

> Scope: documentation + small probe scripts only. No ASUS `.sys`/`.exe`/
> `.dll` files are included. All device paths below were read from the
> author's own machine (Windows 11 Home, BIOS `E1404FA.318`).

## Machine (verified on author hardware)

| Item | Value |
|---|---|
| Model | `Vivobook Go E1404FA_E1404FA`, vendor `ASUSTeK COMPUTER INC.` |
| Board | `E1404FA` |
| BIOS | `E1404FA.318` (AMI, 2026-01-16) |
| CPU | AMD Ryzen 5 7520U w/ Radeon Graphics (Mendocino, 15 W class) |
| Touchpad HID | `ACPI\ASUP1411`, HID `VID_093A` (PixArt), compat `PNP0C50` (I2C HID) |
| ASUS control | `ACPI\ASUS2018` = ASUS System Control Interface v3, `3.1.72.0` |
| ATK WMI GUID | `97845ED0-4E6D-11DE-8A39-0800200C9A66`, methods `DSTS`/`DEVS` etc. |

## What works where

| Feature | Windows 11 (stock) | Linux (expected) |
|---|---|---|
| CPU fan modes (Silent/Balanced/Turbo via MyASUS Fn+F5) | Yes (`AsusOptimization` + `AsusWmiAcpi.sys`) | Via `asus-wmi` `fan_boost_mode` / `throttle_thermal_policy` or `asusctl`/`supergfxctl` if IDs match — verify per §`fan/` |
| Touchpad NumberPad grid + toggle | Yes (`AsusNUMPADFilter` + `AsusNumPadService`) | Via `asus-numberpad-driver` with I2C addr `0x15` — verify per §`numpad/` |
| NumberPad backlight levels | Yes | Same I2C writes (`0x41`–`0x48` family) — verify |
| Top-corner NumLock LED | Yes on Windows | Known problem class on newer `ASUP14xx` (see §`touchpad-led/`, upstream issue #289 pattern) |

## Layout

```text
docs/            verified hardware + Windows driver inventory
numpad/          NumberPad I2C protocol, layouts, Linux port notes
fan/             fan/thermal WMI IDs, registry keys, Linux mapping
touchpad-led/    backlight vs NumLock LED, troubleshooting
firmware/        ACPI/DSDT notes (ETPD, WMNB, _CRS 0x15)
tools/           Dump-E1404FA.ps1, Probe-AsusWMI.ps1, linux/numpad-test.sh
```

## Quick start

1. Read `docs/HARDWARE.md`, then `docs/WINDOWS-DRIVERS.md`.
2. NumberPad → `numpad/README.md`. Fan → `fan/README.md`. LED → `touchpad-led/README.md`.
3. Run `tools/Dump-E1404FA.ps1` on your own E1404FA to compare IDs before
   porting anything.
4. For Linux, start from the linked upstream projects; this repo only adds
   the E1404FA-specific IDs and verification checklists.

## Safety

- Fan/EC experiments can overheat or wear hardware. Change one thing at a
  time, monitor `sensors`/`asusctl`, keep a way back to Balanced/UEFI defaults.
- Raw I2C writes go to the touchpad controller. Use the exact 13-byte frame
  from `numpad/` and the upstream `install_device_check.sh` flow; do not
  fuzz the bus blindly.
- Dual-boot Windows first if you can: confirm each feature works in Windows,
  note the exact toggle sequence, then reproduce on Linux.

## Upstream credits

- `asus-linux-drivers/asus-numberpad-driver` (I2C NumberPad protocol, layouts)
- Linux kernel `drivers/platform/x86/asus-wmi.c` (WMI IDs, fan/thermal policy)
- `asus-linux-org/asusctl` + `supergfxctl` (modern fan/profile control)

## License

MIT — see `LICENSE`. ASUS names/marks belong to their owners.
