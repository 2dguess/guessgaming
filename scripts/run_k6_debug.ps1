$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

. "$PSScriptRoot\k6.local.env.ps1"

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL) -or
    [string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY) -or
    [string]::IsNullOrWhiteSpace($env:USER_JWT)) {
  throw "Please fill scripts/k6.local.env.ps1 first."
}

$jwtParts = ($env:USER_JWT -split '\.').Count
Write-Host "SUPABASE host: $(([uri]$env:SUPABASE_URL).Host)"
Write-Host "USER_JWT parts: $jwtParts (expected 3)"

if ($jwtParts -ne 3) {
  throw "USER_JWT is not a valid JWT format."
}

Write-Host ""
Write-Host "== Smoke test (1 request) =="
k6 run scripts/loadtest_place_bet_smoke_k6.js

Write-Host ""
Write-Host "== Arrival-rate test =="
k6 run scripts/loadtest_1m_rows_hour_k6.js
