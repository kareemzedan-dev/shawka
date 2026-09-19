# Deploy Shawka admin panel to Firebase Hosting (permanent public URL).
# Run from anywhere: .\scripts\deploy-admin.ps1
# Requires Firebase CLI logged in as a project Owner/Editor (gtheft505@gmail.com).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Shawka admin panel deploy starting..." -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter not found in PATH." -ForegroundColor Red
  exit 1
}
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Host "Firebase CLI not found. Install: npm install -g firebase-tools" -ForegroundColor Red
  exit 1
}

Write-Host "Building admin web (release)..." -ForegroundColor Yellow
flutter build web --release -t lib/main_admin.dart --output build/web_admin

# Ensure dedicated Hosting site exists (safe if already created).
Write-Host "Ensuring hosting site shawka-admin ..." -ForegroundColor Yellow
firebase hosting:sites:create shawka-admin --project shawka-689fa 2>$null
firebase target:apply hosting admin shawka-admin --project shawka-689fa

Write-Host "Deploying hosting:admin ..." -ForegroundColor Yellow
firebase deploy --only hosting:admin --project shawka-689fa

Write-Host ""
Write-Host "Deploy finished." -ForegroundColor Green
Write-Host "Open: https://shawka-admin.web.app" -ForegroundColor Green
Write-Host "Anyone with the link can open the panel; only admin accounts can sign in." -ForegroundColor Yellow
