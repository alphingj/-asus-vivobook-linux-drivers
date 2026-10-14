# Windows driver inventory — E1404FA (reference, no binaries)

Do not republish ASUS binaries. This page records names/versions/paths so
others can find the same files on their own machines.

## Touchpad / NumberPad

| Component | Version / date | Path on author machine |
|---|---|---|
| ASUS Precision Touchpad | `17.0.0.16` (ASUSTek, `oem44.inf`) | DriverStore `asusnumpadfilter…` family |
| ASUS Keyboard (Col04) | `21.0.0.16` (`oem45.inf`) | same |
| `AsusNUMPADFilter.sys` (PTP filter) | 2023-05-01 | `…\asusnumpadfilter.inf_amd64_c85a6c0d0c40e77c\` |
| `AsusNumPadService.exe` | 2023-05-01 | same dir (opens HID Col05 via `HidD`/`CreateFile`/`DeviceIoControl`) |
| `AsusInputlocaleMonitor.exe` | 2023-05-01 | same dir |
| `FindCalculator.exe` | 2023-05-01 | same dir (top-left slide = calculator) |
| `I2C HID Device` (MS `hidi2c`) | `10.0.26100.8972` | inbox |
| HID mouse (Col01) | MS `10.0.26100.1150` | inbox |

INF support list covers `ASUE1400–1416`, `ASUF1411/1416`, `ASUP1411/1413/1414`
(plus ELAN/VID_0B05 entries) — i.e. this one filter package serves the whole
NumberPad generation, layout chosen by `NUMPADLAYOUT_*` params.

## ASUS System Control Interface v3 (`ACPI\ASUS2018`)

Driver `3.1.72.0`, 2026-09-14 (`oem63.inf`), package
`asussci2.inf_amd64_197d319fab43e0fe`:

- `ASUSOptimization\`: `AsusOptimization.exe`, `AsusHotkey.exe`,
  `AsusOSD.exe`, `AsusWmiAcpi.sys` (`ATKWMIACPIIO`), Splendid/Tru2Life/ICM
  display DLLs, WiFi RangeBoost/SmartConnect helpers.
- `ASUSSystemAnalysis\`: `AsusSystemAnalysis.exe`, `AsusWinIO64.dll`,
  `AsusSAIO.sys` (direct ISA/EC IO — fan/thermal sensing path).
- `AsusAppService\`, `ASUSSwitch\`, `ASUSSoftwareManager\`,
  `ASUSSystemDiagnosis\`, `AsusECDLL\` (`AsusEC_X64.dll`, `AsusEC_ARM.dll`).

Verified strings in `AsusOptimization.exe` (native, not .NET): `DSTS`/`DEVS`
call sites, `FANMODE`, `THERMALSENSOR`, `SetQuietFan`/`GetFanModeSupported`,
`SetDesktopFanMode`, `SetThermalSensor`, thermal-policy + lid-closed
protection, `FanProfile`/`FanProfileDC`, `QuietFan*`, `FanOverboost`,
`ThermalSensor*`, `DesktopFan`, event
`Global\MyASUSSysDiagFanDustRemovalEvent`, registry bases
`SOFTWARE\ASUS\ASUS System Control Interface\…` and
`SOFTWARE\ASUS\ASUSExpertPanel`. Fn+F5 toggles fan mode via this service.

## Where to look on your machine

- `C:\Windows\System32\DriverStore\FileRepository\asusnumpadfilter.inf_amd64_*\AsusNUMPADFilter.inf`
- `…\asussci2.inf_amd64_*\ASUSOptimization\AsusOptimization.exe`
- Services: `AsusNumPadService`, `ASUSOptimization`, `AsusAppService`,
  `ASUSSystemAnalysis`, `ASUSSystemDiagnosis`, `ASUSSwitch`,
  `ASUSSoftwareManager`
- Registry: `HKLM\SYSTEM\CurrentControlSet\Services\AsusNUMPADFilter\Parameters\AlgoParameters`
  (`NUMPAD_*`, `NUMPADGESTURE_*`, `NUMPADLAYOUT_*`, `LED_*`, `FORCE_*`,
  `HAPTICS_*`), `HKLM\SOFTWARE\ASUS\…`
