# Verified hardware inventory — E1404FA (author machine)

Source: `systeminfo`, CIM (`Win32_ComputerSystemProduct`, `Win32_Processor`,
`Win32_BaseBoard`, `Win32_BIOS`), `Get-PnpDevice`, `driverquery`. Collected
2026-10-14. Serial redacted to `R9N0…36C`.

## System

- Manufacturer: `ASUSTeK COMPUTER INC.`
- Model: `Vivobook Go E1404FA_E1404FA`
- Board: `E1404FA` v1.0
- BIOS: AMI `E1404FA.318`, 2026-01-16
- OS at capture: Windows 11 Home Single Language, x64
- CPU: `AMD Ryzen 5 7520U with Radeon Graphics`, `AuthenticAMD`, 2801 MHz max
- Platform glue: `AMD GPIO AMDI0030` (2.2.0.134), `AMD I2C AMDI0010`
  (1.2.0.126), `AMD SMBus 790B` (5.12.0.44)
- EC: `ACPI\PNP0C09` Embedded Controller present
- Thermal zone: `ACPI\THERMALZONE\THRM` present
- Panel: `MyASUS_Splendid`, `DISPLAY\CMN14E5`
- Battery: `ACPI\PNP0C0A`, name `E140435` (capacities not exposed via WMI here)

## Touchpad / NumberPad (the important one)

- ACPI HID: `ACPI\ASUP1411\1`, service `hidi2c`, upper filter `mshidkmdf`
- Hardware IDs: `ACPI\VEN_ASUP&DEV_1411`, `ACPI\ASUP1411`, `*ASUP1411`
- Compatible ID: `ACPI\PNP0C50` (=> I2C HID transport)
- HID collections (all `HID\ASUP1411&Col0x`):
  - `Col01` mouse, `Col02` ASUS Precision Touchpad, `Col03` Microsoft Input
    Configuration Device, `Col04` ASUS Keyboard, `Col05` vendor-defined
    (`HID\VEN_ASUP&DEV_1411&Col05`, usage `FF00:0001`) — the NumberPad
    control/toggle surface (`AsusNumPadService` opens it via HID).
- Silicon: HID `VID_093A` — PixArt (not ELAN). Expect
  `093A:xxxx` + `ASUP1411:00` names on Linux (`/proc/bus/input/devices`).
- I2C address per DSDT class + upstream: `0x15` (verify with
  `install_device_check.sh` before assuming).
- NumberPad filter driver: `AsusNUMPADFilter.sys` + `AsusNumPadService.exe` +
  `AsusInputlocaleMonitor.exe` + `FindCalculator.exe`, package date
  2023-05-01, touchpad driver `17.0.0.16`, keyboard filter `21.0.0.16`.
- INF algorithm params (`AsusNUMPADFilter.inf`): `LED_*`, `FORCE_*`,
  `HAPTICS_*`, `NUMPAD_00..10`, `NUMPADGESTURE_*`, `NUMPADLAYOUT_*` families
  (multiple panel geometries), `COSUMR_*` consumer-button layout. Full INF
  stays on your own machine — do not republish it; key names are listed in
  `numpad/README.md`.

## ASUS control plane

- `ACPI\ASUS2018` = ASUS System Control Interface v3, driver `3.1.72.0`
  (2026-09-14), kernel part `AsusWmiAcpi.sys` (`ATKWMIACPIIO`), user parts:
  `AsusOptimization.exe`, `AsusHotkey.exe`, `AsusOSD.exe`, `AsusSplendid`,
  `AsusSwitch`, `AsusAppService`, `ASUSSoftwareManager`,
  `ASUSSystemAnalysis` (`AsusSAIO.sys` + `AsusWinIO64.dll` = direct IO),
  `ASUSSystemDiagnosis`, `AsusECDLL` (`AsusEC_X64.dll`).
- WMI: `root\WMI:AsusAtkWmi_WMNB`, GUID
  `{97845ED0-4E6D-11DE-8A39-0800200C9A66}`, methods incl. `INIT BSTS SFUN WDOG
  KBNI SCDG SPEC OSVR VERS SPBL SDSP GDSP GLCD ANVI CBIF MWGF DSTS DEVS`;
  event class `AsusAtkWmiEvent`. `DSTS`/`DEVS` take `Device_ID` (+
  `Control_status`) — the fan/thermal knobs live here (see `fan/`).
- Services running: `AsusAppService`, `AsusNumPadService`,
  `ASUSOptimization`, `AsusScreenXpertHostService`, `ASUSSoftwareManager`,
  `ASUSSwitch`, `ASUSSystemAnalysis`, `ASUSSystemDiagnosis`.

## How to re-verify on another unit

Run `tools/Dump-E1404FA.ps1` and diff the `ASUP1411` IDs, `ASUS2018`
version, and service list. Touchpad silicon (`VID_093A`) and I2C address
are the two fields most likely to differ between revisions.
