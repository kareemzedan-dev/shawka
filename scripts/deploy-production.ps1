# Deploy Firestore rules, indexes, Cloud Functions, and Storage rules.
# Run from project root: .\scripts\deploy-production.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Shawka | Skeena - production deploy starting..." -ForegroundColor Cyan

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Host "Firebase CLI not found. Install: npm install -g firebase-tools" -ForegroundColor Red
  exit 1
}

firebase deploy `
  --only firestore:rules,firestore:indexes,functions,storage

Write-Host "Deploy finished successfully." -ForegroundColor Green
Write-Host "Functions include: notifyOrderStatusChange, processJobQueue, dispatchPushCampaign" -ForegroundColor Yellow
