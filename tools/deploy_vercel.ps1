# Local one-shot deploy when GitHub Actions is not set up yet.
# Requires: Flutter SDK, Node.js (for npx), and `npx vercel login` once.
# Usage (from repo root):  powershell -ExecutionPolicy Bypass -File tools\deploy_vercel.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

flutter build web --release
Copy-Item -Path "vercel.json" -Destination "build\web\vercel.json" -Force
Set-Location build\web
npx vercel@latest deploy --prod --yes
