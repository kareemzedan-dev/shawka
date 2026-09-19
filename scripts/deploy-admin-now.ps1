# One-shot: login (if needed) + deploy Shawka admin to https://shawka-admin.web.app
$ErrorActionPreference = "Stop"
Set-Location "c:\project\shawka\shawka"

Write-Host ""
Write-Host "=== Shawka Admin Deploy ===" -ForegroundColor Cyan
Write-Host "Login with: gtheft505@gmail.com" -ForegroundColor Yellow
Write-Host ""

$accounts = firebase login:list 2>&1 | Out-String
if ($accounts -match "No authorized accounts" -or $accounts -notmatch "@") {
  Write-Host "Opening Firebase login..." -ForegroundColor Yellow
  firebase login
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Login failed." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
  }
} else {
  Write-Host "Already logged in:" -ForegroundColor Green
  Write-Host $accounts
}

if (-not (Test-Path "build\web_admin\index.html")) {
  Write-Host "Building admin web..." -ForegroundColor Yellow
  flutter build web --release -t lib/main_admin.dart --output build/web_admin
}

Write-Host "Linking hosting target admin -> shawka-admin ..." -ForegroundColor Yellow
firebase target:apply hosting admin shawka-admin --project shawka-689fa

Write-Host "Deploying..." -ForegroundColor Yellow
firebase deploy --only hosting:admin --project shawka-689fa

Write-Host ""
Write-Host "Done. Open: https://shawka-admin.web.app" -ForegroundColor Green
Read-Host "Press Enter to close"
