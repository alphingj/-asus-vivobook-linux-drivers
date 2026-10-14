<#
.SYNOPSIS  Read-only hardware dump for ASUS Vivobook Go E1404FA.
.DESCRIPTION
  Collects system, board/BIOS, AMD platform, ASUP1411 touchpad collections,
  ASUS2018 control interface, ATK WMI GUID/methods, drivers, services and
  ASUS registry keys. Writes nothing to hardware. Run in stock PowerShell.
.EXAMPLE  powershell -NoProfile -ExecutionPolicy Bypass -File tools\Dump-E1404FA.ps1
#>
$ErrorActionPreference = 'Continue'
function Section($t){ Write-Host ""; Write-Host ("=== {0} ===" -f $t) }

Section "System"
Get-CimInstance Win32_ComputerSystemProduct | Format-List Name,Vendor,Version,IdentifyingNumber
Get-CimInstance Win32_Processor | Format-List Name,Manufacturer,MaxClockSpeed
Get-CimInstance Win32_BaseBoard | Format-List Product,Manufacturer
Get-CimInstance Win32_BIOS | Format-List SMBIOSBIOSVersion,Manufacturer,ReleaseDate

Section "Touchpad + control PnP"
Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Touch|NumberPad|ATK|ASUS|Thermal|GPIO|I2C|HID' } |
  Select-Object Status,Class,FriendlyName,InstanceId | Format-Table -AutoSize -Wrap
Section "ATK/ACPI IDs"
Get-PnpDevice | Where-Object { $_.InstanceId -match 'ATK|ASUS2018|PNP0C14|ASUP1411|AMDI0010|AMDI0030' } |
  Select-Object Status,Class,FriendlyName,InstanceId | Format-Table -AutoSize -Wrap

Section "HID hardware IDs (ASUP1411)"
'ACPI\ASUP1411\1','HID\ASUP1411&COL05\4&33C65996&0&0004' | ForEach-Object {
  Get-PnpDeviceProperty -InstanceId $_ -KeyName 'DEVPKEY_Device_HardwareIds' -ErrorAction SilentlyContinue |
    Format-List InstanceId,Data
}

Section "WMI ATK surface"
Get-CimClass -Namespace root\WMI | Where-Object { $_.CimClassName -match 'AsusAtkWmi' } |
  Select-Object CimClassName | Format-Table -AutoSize
Get-CimClass -Namespace root\WMI -ClassName AsusAtkWmi_WMNB |
  Select-Object -ExpandProperty CimClassMethods | Format-Table Name,ReturnType -AutoSize
(Get-CimClass -Namespace root\WMI -ClassName AsusAtkWmi_WMNB).CimClassQualifiers |
  Format-Table Name,Value -AutoSize -Wrap

Section "Drivers (ASUS/ATK/HID/AMD)"
Get-WmiObject Win32_PnPSignedDriver |
  Where-Object { $_.DeviceName -match 'ASUS|ATK|Touch|I2C|HID|GPIO|SMBus|System Control' } |
  Select-Object DeviceName,DriverVersion,DriverProviderName,InfName | Format-Table -AutoSize -Wrap

Section "Services"
Get-Service | Where-Object { $_.Name -match 'ASUS|ATK|NumPad' } | Format-Table -AutoSize
Get-CimInstance Win32_Service | Where-Object { $_.Name -match 'NumPad|ASUSOpt|AsusApp' } |
  Select-Object Name,PathName,State | Format-List

Section "ASUS registry (names only)"
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\AsusNUMPADFilter\Parameters\AlgoParameters' -ErrorAction SilentlyContinue |
  Select-Object NUMPAD_*,LED_* | Format-List
Write-Host "Compare against docs/HARDWARE.md and docs/WINDOWS-DRIVERS.md; diff ASUP1411 VID, I2C addr, ASUS2018 version."
