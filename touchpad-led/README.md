# Touchpad LED — backlight vs NumLock indicator

Two different lights, two different failure modes. Do not conflate them.

> One-command sweep: `./install.sh --led-test` (asks before each write).
> Manual values below.

## 1. NumberPad grid backlight

- Same I2C frame as `../numpad/` (`05 00 3d 03 06 00 07 00 0d 14 03 <VAL> ad`
  @ `0x15`): `0x00` off, `0x01`+`0x60` on, `0x41`–`0x48` levels family.
- If the grid never lights on Linux but keys work, the brightness `<VAL>`
  set is wrong for this panel — sweep read-only per
  `../tools/linux/numpad-test.sh` and the upstream FAQ.
- Windows reference: hold top-right icon ~1 s (or corner slide), watch for
  the staged `0x01` then `0x60` + level write.

## 2. Top-corner NumLock/on-off indicator LED

- On Windows this LED follows NumberPad state. On Linux newer `ASUP14xx`
  (PixArt `093A:xxxx`, e.g. `ASUP1414:00 093A:3004` reports) show a known
  issue class: **grid works, corner LED stays dark** across `0x00/0x01/0x60`
  and the whole brightness sweep (upstream `asus-numberpad-driver#289`
  pattern). Root cause is unsettled — possibly a separate HID output report
  / EC flag rather than the I2C level byte.
- E1404FA (`ASUP1411` + `VID_093A`) is in the same silicon family, so expect
  this until disproven. Verification protocol:
  1. Dual-boot Windows: confirm the corner LED lights with NumberPad on.
  2. Linux clean live USB: run `install_device_check.sh`, then send
     `0x01`, `0x60`, `0x41`–`0x48`, `0x20`–`0x2f` one at a time to the
     confirmed bus/addr, watching only the corner LED.
  3. Record which (if any) value moves it. Publish the table.
  4. If none moves it, capture: `/proc/bus/input/devices` touchpad block,
     `DSDT.dsl` ETPD device, `usbhid-dump`/Wireshark USBPcap of the Windows
     toggle (HID output reports to Col05), and file it as an LED-specific
     issue with photos.

## What to capture for a fix

- HID report descriptor of `Col05` (usage `FF00:0001`) + any output/feature
  reports the Windows driver sends on toggle (USBPcap/Wireshark or
  `hidraw` sniffing).
- Whether `AsusNumPadService` `SetLEDState`/`GetLEDState` (symbols observed
  in the 2023 binary) maps to a HID feature report instead of I2C.
- `AsusNUMPADFilter.inf` `LED_*` params on your unit (names only, quoted —
  never republish the INF).
