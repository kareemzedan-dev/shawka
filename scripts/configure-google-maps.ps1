# Configures Google Maps API keys locally (not committed to Git).
#
# طريقة 1 — متغيرات بيئة (الجلسة الحالية فقط):
#   $env:GOOGLE_MAPS_API_KEY_ANDROID = "your-android-key"
#   $env:GOOGLE_MAPS_API_KEY_IOS = "your-ios-key"
#   .\scripts\configure-google-maps.ps1
#
# طريقة 2 — معاملات (مفضّل في PowerShell):
#   .\scripts\configure-google-maps.ps1 -AndroidKey "..." -IosKey "..."
#
# طريقة 3 — إعادة ضبط من الملفات المحلية إن وُجدت مسبقاً:
#   .\scripts\configure-google-maps.ps1 -UseExisting

param(
    [string]$AndroidKey = $env:GOOGLE_MAPS_API_KEY_ANDROID,
    [string]$IosKey = $env:GOOGLE_MAPS_API_KEY_IOS,
    [string]$ApiKey = $env:GOOGLE_MAPS_API_KEY,
    [switch]$UseExisting
)

$root = Split-Path -Parent $PSScriptRoot
$androidProps = Join-Path $root "android\local.properties"
$iosSecrets = Join-Path $root "ios\Flutter\Secrets.xcconfig"
$mapsJson = Join-Path $root "assets\secrets\maps_keys.json"
$rootSecrets = Join-Path $root "secrets.properties"

function Read-AndroidKeyFromFile {
    if (-not (Test-Path $androidProps)) { return $null }
    $line = Get-Content $androidProps | Where-Object { $_ -match '^google\.maps\.apiKey=' } | Select-Object -First 1
    if ($line) { return ($line -replace '^google\.maps\.apiKey=', '').Trim() }
    return $null
}

function Read-IosKeyFromFile {
    if (-not (Test-Path $iosSecrets)) { return $null }
    $line = Get-Content $iosSecrets | Where-Object { $_ -match '^GMS_API_KEY=' } | Select-Object -First 1
    if ($line) { return ($line -replace '^GMS_API_KEY=', '').Trim() }
    return $null
}

function Read-KeysFromJson {
    if (-not (Test-Path $mapsJson)) { return $null, $null }
    try {
        $obj = Get-Content $mapsJson -Raw | ConvertFrom-Json
        return $obj.android, $obj.ios
    } catch {
        return $null, $null
    }
}

if ([string]::IsNullOrWhiteSpace($AndroidKey) -and -not [string]::IsNullOrWhiteSpace($ApiKey)) {
    $AndroidKey = $ApiKey
}
if ([string]::IsNullOrWhiteSpace($IosKey) -and -not [string]::IsNullOrWhiteSpace($ApiKey)) {
    $IosKey = $ApiKey
}

if ($UseExisting -or [string]::IsNullOrWhiteSpace($AndroidKey) -or [string]::IsNullOrWhiteSpace($IosKey)) {
    if ([string]::IsNullOrWhiteSpace($AndroidKey)) {
        $AndroidKey = Read-AndroidKeyFromFile
    }
    if ([string]::IsNullOrWhiteSpace($IosKey)) {
        $IosKey = Read-IosKeyFromFile
    }
    if ([string]::IsNullOrWhiteSpace($AndroidKey) -or [string]::IsNullOrWhiteSpace($IosKey)) {
        $ja, $ji = Read-KeysFromJson
        if ([string]::IsNullOrWhiteSpace($AndroidKey) -and $ja) { $AndroidKey = $ja }
        if ([string]::IsNullOrWhiteSpace($IosKey) -and $ji) { $IosKey = $ji }
    }
}

if ([string]::IsNullOrWhiteSpace($AndroidKey) -or [string]::IsNullOrWhiteSpace($IosKey)) {
    Write-Host ""
    Write-Host "No API keys found. Use one of:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  $env:GOOGLE_MAPS_API_KEY_ANDROID = "your-android-key"'
    Write-Host '  $env:GOOGLE_MAPS_API_KEY_IOS = "your-ios-key"'
    Write-Host '  .\scripts\configure-google-maps.ps1'
    Write-Host ""
    Write-Host '  OR:'
    Write-Host ""
    Write-Host '  .\scripts\configure-google-maps.ps1 -AndroidKey "..." -IosKey "..."'
    Write-Host ""
    exit 1
}

function Set-PropertyLine {
    param([string]$Path, [string]$Key, [string]$Value)
    $lines = @()
    if (Test-Path $Path) {
        $lines = Get-Content $Path | Where-Object { $_ -notmatch "^$([regex]::Escape($Key))=" }
    }
    $lines += "$Key=$Value"
    Set-Content -Path $Path -Value $lines -Encoding UTF8
}

# Android local.properties
$sdkLines = @()
if (Test-Path $androidProps) {
    $sdkLines = Get-Content $androidProps | Where-Object {
        $_ -notmatch '^google\.maps\.apiKey='
    }
} else {
    $sdkLines = @("sdk.dir=C:\\Android\\Sdk")
}
$sdkLines += "google.maps.apiKey=$AndroidKey"
Set-Content -Path $androidProps -Value $sdkLines -Encoding UTF8

# iOS Secrets.xcconfig
$iosDir = Split-Path $iosSecrets -Parent
if (-not (Test-Path $iosDir)) {
    New-Item -ItemType Directory -Path $iosDir -Force | Out-Null
}
Set-Content -Path $iosSecrets -Value @(
    "// Local only - do not commit",
    "GMS_API_KEY=$IosKey"
) -Encoding UTF8

Set-PropertyLine -Path $rootSecrets -Key "google.maps.apiKey" -Value $AndroidKey

$mapsJsonDir = Join-Path $root "assets\secrets"
if (-not (Test-Path $mapsJsonDir)) {
    New-Item -ItemType Directory -Path $mapsJsonDir -Force | Out-Null
}
$jsonBody = @{
    android = $AndroidKey
    ios     = $IosKey
    web     = $AndroidKey
} | ConvertTo-Json -Compress
Set-Content -Path $mapsJson -Value $jsonBody -Encoding UTF8 -NoNewline

Write-Host "Maps keys configured (Android + iOS + web + maps_keys.json). Values not printed." -ForegroundColor Green
Write-Host "Web admin needs: Maps JavaScript API + Places API + localhost referrer on the key."
Write-Host "Next: flutter pub get && flutter run"
