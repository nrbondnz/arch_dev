param (
    [Parameter(Position=0)]
    [ValidateSet("json", "default")]
    [string]$Mode = "default"
)

# PowerShell script to update amplify_outputs.json and lib\amplify_outputs.dart
# Default: Takes the latest JSON file from Downloads and updates the project.
# json: Takes the Dart version and creates the JSON version.

$projectRoot = $PSScriptRoot + "\..\.."
$outputJson = [System.IO.Path]::GetFullPath("$projectRoot\amplify_outputs.json")
$outputDart = [System.IO.Path]::GetFullPath("$projectRoot\lib\amplify_outputs.dart")

if ($Mode -eq "json") {
    Write-Host "Converting $outputDart to $outputJson..."
    
    if (-not (Test-Path $outputDart)) {
        Write-Error "[ERROR] $outputDart not found."
        exit 1
    }

    $dartContent = Get-Content -Path $outputDart -Raw
    
    # Extract JSON between r''' and '''
    if ($dartContent -match "r'''(?s)(.*)'''") {
        $jsonContent = $Matches[1].Trim()
        $jsonContent | Set-Content -Path $outputJson -NoNewline
        Write-Host "[SUCCESS] $outputJson updated from Dart version."
    } else {
        Write-Error "[ERROR] Could not find JSON content in $outputDart."
        exit 1
    }
} else {
    $downloadsDir = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
    
    Write-Host "Looking for latest amplify_outputs*.json in $downloadsDir..."

    # Find the latest file matching amplify_outputs*.json
    $latestFile = Get-ChildItem -Path $downloadsDir -Filter "amplify_outputs*.json" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1

    if ($null -eq $latestFile) {
        Write-Error "[ERROR] No amplify_outputs*.json found in Downloads."
        exit 1
    }

    Write-Host "Found: $($latestFile.FullName)"

    # Copy to project root
    Write-Host "Copying to $outputJson..."
    Copy-Item -Path $latestFile.FullName -Destination $outputJson -Force

    if (-not (Test-Path $outputJson)) {
        Write-Error "[ERROR] Failed to copy file to $outputJson."
        exit 1
    }

    # Generate Dart file
    Write-Host "Generating $outputDart..."
    $jsonContent = Get-Content -Path $outputJson -Raw
    $dartContent = "const amplifyConfig = r'''`n$jsonContent`n''';"
    $dartContent | Set-Content -Path $outputDart -NoNewline

    Write-Host "[SUCCESS] Backend resources updated."
}
