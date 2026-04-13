<#
.SYNOPSIS
  Cleans the ARCH Amplify sandbox then restarts it.

.PARAMETER NoDart
  Run 'npx ampx sandbox' without generating Dart outputs.

.PARAMETER SkipClean
  Skip the cleanup step and just (re)start the sandbox.
#>
param(
    [switch]$NoDart,
    [switch]$SkipClean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot  = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$cleanScript  = Join-Path $PSScriptRoot 'cleanup-sandbox.ps1'

# ── 1. Clean ──────────────────────────────────────────────────────────────────

if (-not $SkipClean) {
    if (-not (Test-Path $cleanScript)) {
        Write-Error "cleanup-sandbox.ps1 not found at $cleanScript"
        exit 1
    }
    Write-Host "=== Running cleanup-sandbox.ps1 ===`n"
    & $cleanScript
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Error "Cleanup failed (exit $LASTEXITCODE). Aborting."
        exit $LASTEXITCODE
    }
} else {
    Write-Host "[SkipClean] Skipping cleanup."
}

# ── 2. Start sandbox ──────────────────────────────────────────────────────────

Push-Location $projectRoot
try {
    if ($NoDart) {
        Write-Host "`n=== Running: npx ampx sandbox ===`n"
        & npx ampx sandbox
    } else {
        Write-Host "`n=== Running: npx ampx sandbox --outputs-format dart --outputs-out-dir lib ===`n"
        & npx ampx sandbox --outputs-format dart --outputs-out-dir lib
    }
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($exitCode -ne 0) {
    Write-Host "`nSandbox exited with code $exitCode."
}
exit $exitCode
