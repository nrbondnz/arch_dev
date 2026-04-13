<#
.SYNOPSIS
  Deletes all ARCH DynamoDB sandbox tables, kills node processes, removes .amplify
  folders, then runs 'npx ampx sandbox delete'.

.PARAMETER SkipDelete
  Skip the 'npx ampx sandbox delete' step (useful if the stack is already gone).
#>
param(
    [switch]$SkipDelete
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ARCH model names - Amplify Gen 2 table names contain these substrings
$archPrefixes = @(
    'Job',
    'Quote',
    'QuoteLineItem',
    'Stage',
    'WorkPackage',
    'Variation',
    'StageClaim',
    'Task',
    'DailyLog'
)

# ---------------------------------------------------------------------------
# Helper: delete all DynamoDB tables whose name contains $Prefix
# ---------------------------------------------------------------------------

function Remove-TablesContaining {
    param([string]$Prefix)

    Write-Host ""
    Write-Host "Searching for DynamoDB tables containing: $Prefix"

    $allTables    = @()
    $startToken   = $null
    $keepPaging   = $true

    while ($keepPaging) {
        $awsArgs = @('dynamodb', 'list-tables', '--no-cli-pager', '--output', 'json')
        if ($startToken) {
            $awsArgs += '--starting-token'
            $awsArgs += $startToken
        }

        $rawJson = & aws @awsArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "aws dynamodb list-tables failed (exit $LASTEXITCODE) - skipping $Prefix"
            return
        }

        $page     = $rawJson | ConvertFrom-Json
        $matching = $page.TableNames | Where-Object { $_ -like "*$Prefix*" }
        if ($matching) {
            $allTables += $matching
        }

        if ($page.NextToken) {
            $startToken = $page.NextToken
        } else {
            $keepPaging = $false
        }
    }

    if ($allTables.Count -eq 0) {
        Write-Host "  No tables found."
        return
    }

    foreach ($tableName in $allTables) {
        Write-Host "  Deleting: $tableName"
        & aws dynamodb delete-table --no-cli-pager --table-name $tableName | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  delete-table failed for $tableName - continuing"
            continue
        }
        Write-Host "  Waiting for deletion to complete..."
        & aws dynamodb wait table-not-exists --no-cli-pager --table-name $tableName
        Write-Host "  Deleted: $tableName"
    }
}

# ---------------------------------------------------------------------------
# 1. Kill stale node processes
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Killing node.exe processes..."
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# ---------------------------------------------------------------------------
# 2. Delete ARCH DynamoDB tables
# ---------------------------------------------------------------------------

foreach ($prefix in $archPrefixes) {
    Remove-TablesContaining -Prefix $prefix
}

# ---------------------------------------------------------------------------
# 3. Remove .amplify folders
# ---------------------------------------------------------------------------

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

foreach ($dir in @($projectRoot.Path, $PSScriptRoot)) {
    $amplifyDir = Join-Path $dir '.amplify'
    if (Test-Path $amplifyDir) {
        Write-Host ""
        Write-Host "Removing $amplifyDir"
        Remove-Item -Recurse -Force $amplifyDir
    }
}

# ---------------------------------------------------------------------------
# 4. Delete the sandbox stack
# ---------------------------------------------------------------------------

if (-not $SkipDelete) {
    Write-Host ""
    Write-Host "Deleting Amplify sandbox stack..."
    Push-Location $projectRoot
    try {
        & npx ampx sandbox delete -y
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "sandbox delete exited with $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "[SkipDelete] Skipping 'npx ampx sandbox delete'."
}

Write-Host ""
Write-Host "Cleanup complete."
