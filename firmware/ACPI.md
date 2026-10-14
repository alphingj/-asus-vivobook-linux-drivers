# ACPI / firmware notes — E1404FA

`EnumSystemFirmwareTables(ACPI)` returned empty from the author's stock
PowerShell (no admin firmware-table access), so no DSDT is shipped here.
Dump your own — it is the single most valuable artifact for both fan and
NumberPad work.

## Dump it (Linux live USB, recommended)

```bash
sudo apt-get install -y iasl
sudo cp /sys/firmware/acpi/tables/DSDT DSDT
iasl -d DSDT   # -> DSDT.dsl
grep -n -A40 'Device (ETPD)' DSDT.dsl | head -80
grep -n 'WMNB\|ASUSWMI\|97845ED0' DSDT.dsl | head -20
```

Windows alternatives: RWEverything (ACPI tables view) or AcpiDumpEx. Save
`DSDT.dsl` privately; quote only the relevant `ETPD`/`WMNB` snippets in
issues.

## What to look for

- `Device (ETPD)`: `_HID` returning `ASUP1411` (via `TPDI`/`TPHI` + `ETPH`/
  `PTPH` tables), `_CID PNP0C50`, `_CRS` with `I2cSerialBusV2 (0x0015, …)`
  + GPIO int. Confirms the `0x15` address and wake pin.
- `_DSM` UUID `3cdff6f7-4267-4555-ad05-b30a3d8938de` (HID-I2C device).
- `WMNB` method + `_UID`: `ATK` => `DSTS` (`0x53545344`); `ASUSWMI` =>
  `DCTS` (`0x53544344`). Author WMI exposes the `97845ED0-…` GUID with
  `ATK`-style `DSTS`/`DEVS` — expect `_UID ATK` here.
- `THRM` thermal zone + EC (`PNP0C09`) opregions for the fan path.
- `TPDI`/`TPHI`/`TPIF`/`DSYN` flags selecting the touchpad variant.

## Redaction

Scrub `Serial`, `UUID`, Windows keys, and any `NH…`-style personalization
before posting a DSDT anywhere.
