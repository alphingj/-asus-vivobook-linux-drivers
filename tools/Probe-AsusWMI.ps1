<#
.SYNOPSIS  Read-only ASUS WMI DSTS probe (one ID per run).
.DESCRIPTION
  Calls root\WMI AsusAtkWmi_WMNB.DSTS(Device_ID) for a single candidate fan/
  thermal ID and prints the hex status. Does NOT call DEVS (no writes).
  ATK WMI can block; each probe runs as a job with a timeout (default 15 s).
.PARAMETER DeviceId  Hex ID, e.g. '00110019'. Defaults to the Vivo fan ID.
.PARAMETER TimeoutSec Job timeout. Default 15.
.EXAMPLE  powershell -NoProfile -ExecutionPolicy Bypass -File tools\Probe-AsusWMI.ps1 -DeviceId 00110019
#>
param([string]$DeviceId = '00110019', [int]$TimeoutSec = 15)
$ErrorActionPreference = 'Stop'
$v = [Convert]::ToUInt32($DeviceId, 16)
Write-Host ("Probing DSTS 0x{0} (read-only, timeout {1}s)..." -f $DeviceId, $TimeoutSec)
$job = Start-Job -ScriptBlock {
  param($id)
  (Invoke-CimMethod -Namespace root\WMI -ClassName AsusAtkWmi_WMNB -MethodName DSTS -Arguments @{ Device_ID = [uint32]$id }).device_status
} -ArgumentList $v
if (Wait-Job $job -Timeout $TimeoutSec) {
  $r = Receive-Job $job
  Write-Host ("DSTS 0x{0} => 0x{1:X8}" -f $DeviceId, [uint32]$r)
  Write-Host "Presence bit = bit0 of byte0; 0xFFFFFFFF/empty usually means unsupported."
} else {
  Write-Host ("TIMEOUT after {0}s - WMI did not answer; treat as no-data, stop." -f $TimeoutSec)
  Stop-Job $job | Out-Null
}
Remove-Job $job -Force -ErrorAction SilentlyContinue
Write-Host "Suggested read-only order: 00110019, 00110018, 00120075, 00110011. Never run DEVS blind."
