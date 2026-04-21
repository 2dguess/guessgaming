# Gets a user access_token (JWT) for k6 / REST testing.
# Usage (PowerShell):
#   cd c:\Users\hp\gmaing
#   .\scripts\get_supabase_user_jwt.ps1
#
# Prerequisites: set these in the SAME shell BEFORE running, or edit the empty strings below once (do not commit real values).
#   $env:SUPABASE_URL = "https://YOUR_REF.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#
# Password is prompted securely (not echoed). Nothing is written to disk.

$ErrorActionPreference = 'Stop'

$url = $env:SUPABASE_URL
$anon = $env:SUPABASE_ANON_KEY

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($anon)) {
  Write-Host "Set SUPABASE_URL and SUPABASE_ANON_KEY first, e.g."
  Write-Host '  $env:SUPABASE_URL = "https://YOUR_REF.supabase.co"'
  Write-Host '  $env:SUPABASE_ANON_KEY = "eyJ..."'
  exit 1
}

$u = [Uri]$url.TrimEnd('/')
$hostName = $u.Host
if (-not $hostName.EndsWith('.supabase.co')) {
  Write-Host "SUPABASE_URL should look like https://xxxxx.supabase.co"
  exit 1
}
$ref = $hostName.Replace('.supabase.co', '')

$email = Read-Host "Email"
$sec = Read-Host "Password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
} finally {
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

$bodyObj = @{ email = $email; password = $plain } | ConvertTo-Json
$plain = $null
$sec.Dispose()

$tokenUri = "https://$ref.supabase.co/auth/v1/token?grant_type=password"

try {
  $r = Invoke-RestMethod -Uri $tokenUri -Method Post `
    -Headers @{ apikey = $anon; 'Content-Type' = 'application/json' } `
    -Body $bodyObj
} catch {
  Write-Host "Request failed: $($_.Exception.Message)"
  if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
  exit 1
}

if (-not $r.access_token) {
  Write-Host "No access_token in response."
  exit 1
}

$env:USER_JWT = $r.access_token
$parts = ($env:USER_JWT -split '\.').Count
Write-Host ""
Write-Host "OK: USER_JWT set for this PowerShell session (JWT parts: $parts, expected 3)."
Write-Host "Next (same window):"
Write-Host '  cd c:\Users\hp\gmaing'
Write-Host '  k6 run --vus 1 --iter 1 scripts/loadtest_place_bet_k6.js'
