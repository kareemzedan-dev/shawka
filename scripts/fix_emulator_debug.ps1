# إصلاح جذري لمشاكل Debug على محاكي Android (Windows)
# powershell -ExecutionPolicy Bypass -File scripts\fix_emulator_debug.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { throw "adb not found at $adb" }

$packageId = "com.matlob.go.matlobgo"
$device = "emulator-5554"

Write-Host "==> Checking emulator..."
if ((& $adb devices) -notmatch "$device\s+device") {
  throw "Emulator $device is not online. Start it first."
}

Write-Host "==> Restarting ADB..."
& $adb kill-server | Out-Null
Start-Sleep -Seconds 1
& $adb start-server | Out-Null
& $adb wait-for-device | Out-Null

Write-Host "==> Uninstalling old builds (debug/release signature clash)..."
& $adb -s $device uninstall $packageId 2>$null | Out-Null
& $adb -s $device reverse --remove-all 2>$null | Out-Null

Write-Host "==> flutter run (Skia + no-dds + fixed port)..."
flutter run -d $device `
  --no-enable-impeller `
  --no-dds `
  --host-vmservice-port=8391 `
  lib/main.dart
