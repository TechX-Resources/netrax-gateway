# NETRAX AI Gateway - local demo on Windows (Docker Desktop + Ollama)
# Run from the repository folder:  .\scripts\windows\Start-NETRAX.bat
# Windows PowerShell 5.1 turns anything a program writes to stderr (warnings,
# progress bars) into an error when this is "Stop", so check exit codes instead.
$ErrorActionPreference = "Continue"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repo
$model = if ($env:NETRAX_LOCAL_MODEL) { $env:NETRAX_LOCAL_MODEL } else { "llama3.2" }

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

Step "Checking Docker Desktop"
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker Desktop is not running. Start it, wait until it says 'Engine running', then run this again." }

Step "Checking Ollama"
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) { throw "Ollama is not installed or not on PATH. Install it from https://ollama.com and run this again." }
try { Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5 -ErrorAction Stop | Out-Null }
catch { Write-Host "Starting Ollama..."; Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden; Start-Sleep 5 }

Step "Downloading local model '$model' (first time only)"
ollama pull $model
if ($LASTEXITCODE -ne 0) { throw "Could not download model $model" }

Step "Writing config.yaml (route mode, local model via Ollama, dashboard on)"
if (-not (Test-Path config.yaml)) {
  $cfg = Get-Content config.example.yaml -Raw
  $cfg = $cfg -replace '(?m)^mode: mask', 'mode: route'
  $cfg = $cfg -replace 'base_url: http://localhost:11434', 'base_url: http://host.docker.internal:11434'
  $cfg = $cfg -replace '(?m)^(\s*)model: llama3\.2', "`${1}model: $model"
  $cfg = $cfg -replace '(?m)^dashboard:\r?\n(\s*)enabled: false', "dashboard:`n`${1}enabled: true"
  [System.IO.File]::WriteAllText((Join-Path $repo "config.yaml"), $cfg, (New-Object System.Text.UTF8Encoding $false))
} else { Write-Host "config.yaml already exists - keeping it." }
New-Item -ItemType Directory -Force data | Out-Null

Step "Building and starting NETRAX (first build takes several minutes)"
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose failed" }

Step "Waiting for NETRAX to be ready"
$ok = $false
for ($i = 0; $i -lt 90; $i++) {
  try { Invoke-RestMethod http://localhost:3000/health -TimeoutSec 3 -ErrorAction Stop | Out-Null; $ok = $true; break } catch { Start-Sleep 4 }
}
if (-not $ok) { docker compose logs --tail 60; throw "NETRAX did not become healthy. Logs are above." }

Step "Sending a test request that contains client details"
$body = @{
  model = "gpt-4o-mini"
  messages = @(@{ role = "user"; content = "Summarize the settlement terms for Maria Gonzalez, phone 617-555-0142, email m.gonzalez@example.com, in two sentences." })
} | ConvertTo-Json -Depth 5
try {
  $resp = Invoke-WebRequest http://localhost:3000/openai/v1/chat/completions -Method Post -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
} catch { Write-Host "Test request failed: $($_.Exception.Message)" -ForegroundColor Yellow; Start-Process "http://localhost:3000/dashboard"; exit 1 }
$json = $resp.Content | ConvertFrom-Json
Write-Host ("Sensitive details detected: " + $resp.Headers["X-PasteGuard-PII-Detected"])
Write-Host ("Answered by:                " + $resp.Headers["X-PasteGuard-Provider"])
Write-Host ("Answer: " + $json.choices[0].message.content)

Step "Opening the dashboard"
Start-Process "http://localhost:3000/dashboard"
Write-Host "`nNETRAX is running. Stop it with:  docker compose down" -ForegroundColor Green
