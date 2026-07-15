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
    $lines = Get-Content $path
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
$proj = Get-Content $projPath -Raw
$proj = [regex]::Replace($proj, 'config/version="[^"]*"', "config/version=`"$Version`"")
Set-Content -Path $projPath -Value $proj -Encoding utf8 -NoNewline

# --- 2. Export ------------------------------------------------------------
Info "Exporting Windows Desktop build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
# --import first so a clean checkout has its resources imported before export.
& $Godot --headless --path $Root --import 2>&1 | Out-Null
& $Godot --headless --path $Root --export-release "Windows Desktop" $ExePath
$exportExit = $LASTEXITCODE
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
