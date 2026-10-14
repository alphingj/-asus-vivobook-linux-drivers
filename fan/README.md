# CPU fan / thermal control — E1404FA

Single-fan Vivobook (Ryzen 5 7520U, ~15 W). Windows exposes Silent / Balanced
(/ Performance) + dust-removal through MyASUS (`ASUSOptimization` + `Fn+F5`);
the EC + `AsusSAIO`/`AsusWmiAcpi` drivers do the work. Nothing here writes
the EC — read-only discovery first.

## Control path (verified)

```text
Fn+F5 / MyASUS Fan Profile
  -> AsusOptimization.exe  --DSTS/DEVS-->  ATKWMIACPIIO (AsusWmiAcpi.sys)
  -> BIOS WMNB (GUID 97845ED0-4E6D-11DE-8A39-0800200C9A66)  -> EC / fans
  -> AsusSystemAnalysis (AsusSAIO.sys + AsusWinIO64.dll) reads temps/sensors
```

`root\WMI:AsusAtkWmi_WMNB` methods include `DSTS(Device_ID)` (read status)
and `DEVS(Device_ID, Control_status)` (write). `DSTS` presence bit tells
whether an ID exists on your BIOS rev.

## WMI device IDs (from upstream kernel `asus-wmi`, check on E1404FA)

| ID | Upstream name | Likely E1404FA role |
|---|---|---|
| `0x00110018` | `FAN_BOOST_MODE` | fan mode 0 normal / 1 overboost / 2 silent (older) |
| `0x00110019` | `FAN_BOOST_MODE2` / Vivo throttle policy | **most likely on this Vivobook**: 0 normal / 1 silent / 2 overboost mapping differs — verify |
| `0x00120075` | `THROTTLE_THERMAL_POLICY` | 0 default / 1 overboost / 2 silent (TUF-style; may also exist) |
| `0x00110011` | `THERMAL_CTRL` | temperature readout (low 16 bits, deci-Kelvin) |
| `0x00110012` | `FAN_CTRL` (deprecated) | legacy fan PWM/RPM if exposed |
| `0x00110013` / `0x00110014` | `CPU_FAN_CTRL` / `GPU_FAN_CTRL` | per-fan if exposed (single fan => CPU) |

`0x00120012` (`PROCESSOR_STATE`) and `0x00060013` (camera on some tables)
are unrelated — do not poke them for fan work.

Read-only probe order: `0x00110019`, `0x00110018`, `0x00120075`,
`0x00110011`. Use `tools/Probe-AsusWMI.ps1` (one ID per run, logs `DSTS`
hex). A missing ID returns `~0`/`ENODEV`-style; that is a finding, not an
error. **Do not call `DEVS` until reads are understood and temps are
monitored.**

## Windows registry knobs (observed strings, author machine)

- `SOFTWARE\ASUS\ASUS System Control Interface\AsusOptimization\…`:
  `FanProfile`, `FanProfileDC`, `FanOverboost`, `QuietFan`, `QuietFanDC`,
  `QuietFanSupported`, `ThermalSensor`, `ThermalSensorLimit`, `DesktopFan`
- Event `Global\MyASUSSysDiagFanDustRemovalEvent` (dust-removal full-speed)
- Methods named `GetFanModeSupported`, `SetQuietFan`, `SetDesktopFanMode`,
  `GetThermalSensor`/`SetThermalSensor`, `FANMODE`/`THERMALSENSOR` loop
  threads.

## Linux mapping

- Kernel `asus-wmi`: `…/fan_boost_mode`, `…/throttle_thermal_policy`,
  `hwmon` `fan1_input`/`pwm1` if the BIOS exposes them. Debugfs
  `asus-wmi/{dev_id,ctrl_param,method_id,devs,dsts,call}` can re-run the
  same reads.
- `asusctl`/`supergfxctl` (+ ROG tools on non-ROG Vivobooks where supported):
  profile switching usually maps onto the same two IDs above.
- AMD side: `k10temp`/`amdgpu` + `sensors` for die temps; fan RPM only
  appears if `asus-wmi` hwmon binds — on many Vivobooks it does not, and
  mode-switch + acoustics/temps is the practical API.

## Safe verification checklist

1. Boot Windows, record idle/load temps + acoustics per profile
   (Silent/Balanced/Turbo) + `Fn+F5` behavior.
2. Boot Linux, check `ls /sys/devices/platform/asus*`, `sensors`, dmesg
   `asus_wmi` lines.
3. Read `DSTS` for the three candidate IDs (Windows probe or Linux debugfs),
   record presence bits.
4. Only then test one mode write, watching temps; keep UEFI defaults as the
   way back. Repaste/repad advice is out of scope.
