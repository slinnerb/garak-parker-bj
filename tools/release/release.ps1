<#
.SYNOPSIS
    Build a Windows export and publish it as a GitHub Release so players'
    "Check for Updates" button sees the new version.

.DESCRIPTION
    One command to ship an update to your friend:
      1. Sets [application] config/version in project.godot to -Version.
      2. Exports the "Windows Desktop" preset to build\.
      3. Zips the build.
      4. Creates a GitHub release tagged vX.Y.Z with the zip attached.

    Requirements (checked below):
      - Godot 4.7 with EXPORT TEMPLATES installed (Editor > Manage Export
        Templates > Download and Install). Without templates, export fails.
      - gh CLI authenticated (gh auth status).
      - core/update/update_config.gd has GITHUB_REPO set.

.EXAMPLE
    ./tools/release/release.ps1 -Version 0.2.0 -Notes "Adds combat prototype."

.EXAMPLE
    ./tools/release/release.ps1 -Version 0.2.0 -DryRun   # build + zip, no publish
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$Notes = "",

    # Path to the Godot 4.7 editor executable. Override with env GODOT_BIN.
    [string]$Godot = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\CricketsGame\TheLastUpdate\Godot_v4.7-stable_win64.exe" }),

    # Build and zip but do not publish to GitHub.
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Tag = "v$Version"
$BuildDir = Join-Path $Root "build"
$ExeName = "ReincarnationRoguelike.exe"
$ExePath = Join-Path $BuildDir $ExeName
$ZipName = "ReincarnationRoguelike-$Tag-windows.zip"
$ZipPath = Join-Path $BuildDir $ZipName

function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# Pulls the release notes for a version out of CHANGELOG.md so the changelog is
# the single source of truth. Returns the text under "## [version]" (or
# "## [Unreleased]" as a fallback) up to the next "## " header. Empty if absent.
function Get-ChangelogNotes($Root, $Version) {
    $path = Join-Path $Root "CHANGELOG.md"
    if (-not (Test-Path $path)) { return "" }
    # UTF-8 so arrows/em-dashes in the notes don't turn into mojibake.
    $lines = Get-Content $path -Encoding UTF8
    $wanted = "## [$Version]"
    $fallback = "## [Unreleased]"
    foreach ($header in @($wanted, $fallback)) {
        $start = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].StartsWith($header)) { $start = $i; break }
        }
        if ($start -ge 0) {
            $body = @()
            for ($j = $start + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j].StartsWith("## ")) { break }
                $body += $lines[$j]
            }
            $text = ($body -join "`n").Trim()
            if ($text) { return $text }
        }
    }
    return ""
}

# --- Preflight -------------------------------------------------------------
if (-not (Test-Path $Godot)) {
    Fail "Godot not found at '$Godot'. Set -Godot or `$env:GODOT_BIN."
}
if (-not $DryRun) {
    gh auth status 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "gh CLI is not authenticated. Run: gh auth login" }
}

$configPath = Join-Path $Root "core\update\update_config.gd"
if ((Get-Content $configPath -Raw) -match 'GITHUB_REPO\s*:=\s*""') {
    Write-Host "WARNING: GITHUB_REPO is empty in core/update/update_config.gd." -ForegroundColor Yellow
    Write-Host "         Players won't be able to check for updates until you set it." -ForegroundColor Yellow
}

# --- 1. Bump version in project.godot -------------------------------------
Info "Setting version to $Version in project.godot"
$projPath = Join-Path $Root "project.godot"
# Read/write via .NET so UTF-8 stays intact: PowerShell 5.1's Get-Content/
# Set-Content round-trip corrupts non-ASCII (em-dashes) and injects a BOM.
$proj = [System.IO.File]::ReadAllText($projPath)
$proj = [regex]::Replace($proj, 'config/version="[^"]*"', "config/version=`"$Version`"")
[System.IO.File]::WriteAllText($projPath, $proj, (New-Object System.Text.UTF8Encoding($false)))

# --- 2. Export ------------------------------------------------------------
Info "Exporting Windows Desktop build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
# Remove any prior exe so a failed/partial export can't leave a stale binary
# that the artifact check would then happily zip and ship.
if (Test-Path $ExePath) { Remove-Item $ExePath -Force }
# --import first so a clean checkout has its resources imported before export.
& $Godot --headless --path $Root --import 2>&1 | Out-Null
& $Godot --headless --path $Root --export-release "Windows Desktop" $ExePath
$exportExit = $LASTEXITCODE
# The exported exe can land on disk a moment AFTER Godot exits (a 100 MB write
# plus real-time AV scanning lag behind the process). Wait for it — otherwise a
# race lets the next steps zip a stale/half-written binary (this shipped 0.1.0
# as "v0.1.1" once). Combined with the pre-export delete above, "exe present"
# now truly means "this export produced it".
$deadline = (Get-Date).AddSeconds(90)
while (-not (Test-Path $ExePath) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
# Judge success by the artifact, not the exit code: Godot can return non-zero for
# non-fatal export warnings (or a cold import cache) yet still produce a working
# exe. Only a MISSING exe is a real failure (usually missing export templates).
if (-not (Test-Path $ExePath)) {
    Write-Host ""
    Write-Host "Export failed. The most common cause is missing export templates." -ForegroundColor Yellow
    Write-Host "Fix: open the project in Godot 4.7, then Editor > Manage Export" -ForegroundColor Yellow
    Write-Host "     Templates > Download and Install (match 4.7-stable)." -ForegroundColor Yellow
    Fail "Godot export did not produce $ExePath"
}
if ($exportExit -ne 0) {
    Write-Host "NOTE: Godot export returned exit $exportExit but produced the exe; continuing." -ForegroundColor DarkYellow
}

# Verify the exported build actually reports the target version. A stale export
# can bake in the previous version even when project.godot is correct, which
# makes the auto-updater loop forever (it downloads a build that still looks old).
Info "Verifying the built exe reports v$Version"
$bootLog = & $ExePath --headless --quit-after 90 2>&1 | Out-String
$m = [regex]::Match($bootLog, 'Logger online \(version ([0-9][^)]*)\)')
$builtVersion = if ($m.Success) { $m.Groups[1].Value.Trim() } else { "<unknown>" }
if ($builtVersion -ne $Version) {
    Fail "Exported build reports version '$builtVersion' but expected '$Version'. Aborting to avoid shipping a stale build. Re-run the release."
}
Info "Confirmed: the build reports v$Version"

# --- 3. Zip ---------------------------------------------------------------
Info "Packaging $ZipName"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
# Zip the exe (embed_pck=true means the exe is self-contained) plus a readme.
Compress-Archive -Path $ExePath -DestinationPath $ZipPath -Force

# --- 4. Publish -----------------------------------------------------------
if ($DryRun) {
    Info "DryRun: skipping GitHub release. Artifact at $ZipPath"
    exit 0
}

if (-not $Notes) { $Notes = Get-ChangelogNotes -Root $Root -Version $Version }
if (-not $Notes) { $Notes = "Release $Tag" }
Info "Creating GitHub release $Tag"
# Pass notes via a file: the changelog contains markdown ([], &, unicode) that
# PowerShell mangles when handed straight to a native command as an argument.
$NotesFile = Join-Path $BuildDir "release_notes.md"
Set-Content -Path $NotesFile -Value $Notes -Encoding utf8
gh release create $Tag $ZipPath --title "Reincarnation Roguelike $Tag" --notes-file $NotesFile
if ($LASTEXITCODE -ne 0) { Fail "gh release create failed." }

Info "Done. Players on older versions will now see an update."
Write-Host "    Remember to commit the version bump: git commit -am 'Release $Tag'" -ForegroundColor DarkGray
