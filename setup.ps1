#Requires -Version 5.1
#Requires -PSEdition Desktop
# Merges the settings a plugin cannot carry. Run with Windows PowerShell:
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -ProjectRoot <folder>
# Use -HomeDir only to test against copies.
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [string]$HomeDir = $env:USERPROFILE
)
$ErrorActionPreference = 'Stop'

# Returns the settings file with the missing entries merged in. Does not write.
function Get-MergedSettings([string]$Path, [string]$Section, [string[]]$Entries) {
    $exists = Test-Path -LiteralPath $Path
    $data = [pscustomobject]@{}
    if ($exists) {
        try { $data = [IO.File]::ReadAllText($Path) | ConvertFrom-Json }
        catch { throw "Invalid JSON in ${Path}: $($_.Exception.Message)" }
        if ($data -isnot [Management.Automation.PSCustomObject]) { throw "Not a JSON object: $Path" }
    }
    if (-not $data.PSObject.Properties[$Section]) {
        $data | Add-Member -NotePropertyName $Section -NotePropertyValue ([pscustomobject]@{})
    }
    $node = $data.$Section
    if ($node -isnot [Management.Automation.PSCustomObject]) { throw "'$Section' is not an object in $Path" }
    $current = [object[]]@()
    if ($node.PSObject.Properties['allow']) {
        if ($node.allow -isnot [array]) { throw "'$Section.allow' is not an array in $Path" }
        $current = $node.allow
    }
    $missing = @($Entries | Where-Object { $current -cnotcontains $_ })
    if ($missing.Count) {
        $node | Add-Member -NotePropertyName allow -NotePropertyValue ([object[]]($current + $missing)) -Force
    }
    [pscustomobject]@{
        Path = $Path; Exists = $exists; Changed = [bool]$missing.Count
        Json = ConvertTo-Json -InputObject $data -Depth 100
    }
}

try {
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Folder not found: $ProjectRoot" }
    $root = (Get-Item -LiteralPath $ProjectRoot).FullName.TrimEnd('\')
    if ($root -match '^[A-Za-z]:$') { throw 'ProjectRoot must be a folder, not a whole drive.' }

    # Both files are read and checked before either is written.
    $files = @(
        Get-MergedSettings (Join-Path $HomeDir '.claude\settings.json') 'autoMode' @(
            '$defaults'
            "Running the Antigravity CLI (agy -p) to send task prompts and source files from my own projects under $root to Google Gemini models is allowed, except secrets, credentials and personal data, and never with --dangerously-skip-permissions"
        )
        Get-MergedSettings (Join-Path $HomeDir '.gemini\antigravity-cli\settings.json') 'permissions' @(
            'command(ls)', 'command(cat)', 'command(grep)', 'command(rg)',
            'command(git status)', 'command(git diff)', 'command(git log)'
        )
    )
    $utf8 = New-Object Text.UTF8Encoding $false
    foreach ($f in $files) {
        if (-not $f.Changed) { "Unchanged: $($f.Path)"; continue }
        if ($f.Exists) {
            $backup = "$($f.Path).bak-$(Get-Date -Format yyyyMMdd-HHmmss-fff)"
            Copy-Item -LiteralPath $f.Path -Destination $backup
            "Backup:    $backup"
        } else {
            [void](New-Item -ItemType Directory -Force -Path (Split-Path $f.Path))
        }
        [IO.File]::WriteAllText($f.Path, $f.Json, $utf8)
        "Updated:   $($f.Path)"
    }
} catch {
    [Console]::Error.WriteLine("setup.ps1 failed: $($_.Exception.Message)")
    exit 1
}
