# Apply CORS to Tarfa / MatlobGo Firebase Storage bucket (Flutter Web image prefetch).
# Requires: Google Cloud SDK (gsutil) + gcloud auth login + active billing

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$CorsFile = Join-Path $Root "storage-cors.json"
$Bucket = "gs://shawka-689fa.firebasestorage.app"

function Find-Gsutil {
    $cmd = Get-Command gsutil -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd",
        "$env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd",
        "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

$gsutil = Find-Gsutil
if (-not $gsutil) {
    Write-Host ""
    Write-Host "gsutil not found. Install Google Cloud SDK first:" -ForegroundColor Yellow
    Write-Host "  winget install Google.CloudSDK --source winget"
    Write-Host "  https://cloud.google.com/sdk/docs/install#windows"
    Write-Host ""
    exit 1
}

if (-not (Test-Path $CorsFile)) {
    Write-Error "Missing CORS file: $CorsFile"
}

Write-Host "Using gsutil: $gsutil" -ForegroundColor Green
Write-Host "Applying CORS from $CorsFile to $Bucket ..."

& $gsutil cors set $CorsFile $Bucket
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "FAILED to set CORS (exit code $LASTEXITCODE)." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common causes:" -ForegroundColor Yellow
    Write-Host "  1. Billing disabled on project shawka-689fa"
    Write-Host "     Fix: https://console.firebase.google.com/project/shawka-689fa/usage/details"
    Write-Host "     Or:  https://console.cloud.google.com/billing"
    Write-Host "  2. Not logged in: gcloud auth login"
    Write-Host "  3. Wrong project:  gcloud config set project shawka-689fa"
    Write-Host ""
    Write-Host "You can also set CORS manually in Google Cloud Console:" -ForegroundColor Cyan
    Write-Host "  Storage -> shawka-689fa.firebasestorage.app -> Configuration -> CORS"
    Write-Host ""
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Verifying CORS ..."
$corsGet = & $gsutil cors get $Bucket 2>&1
$corsText = $corsGet | Out-String
Write-Host $corsText

if ($corsText -match "has no CORS configuration") {
    Write-Host ""
    Write-Host "CORS is still empty. Check billing and permissions." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "CORS applied successfully. Hard-refresh the browser with Ctrl+Shift+R." -ForegroundColor Green
exit 0
