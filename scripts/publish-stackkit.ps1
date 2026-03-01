<#
.SYNOPSIS
    Publishes StackKit content from the private dev repo to the public repo.

.DESCRIPTION
    Syncs shared components (base schemas, CLI, internal packages, platforms,
    tests, docs) and a specific StackKit directory from the private dev repo
    to the public open-source repo.

    Internal-only content (API server, modules, addons, admin tools, internal
    docs, CI config, secrets) is never copied.

    Uses robocopy /MIR for directory sync (handles additions + deletions).

.PARAMETER Kit
    Which StackKit to publish. Use "none" to sync only shared components.

.PARAMETER DryRun
    Show what would be copied without making changes.

.PARAMETER SkipValidation
    Skip post-sync CUE and Go build validation.

.PARAMETER SkipShared
    Skip syncing shared components (only sync the kit directory).

.PARAMETER DevRepo
    Path to the private dev repo. Defaults to this script's parent repo.

.PARAMETER PubRepo
    Path to the public repo.

.EXAMPLE
    .\publish-stackkit.ps1 -Kit base-kit
    .\publish-stackkit.ps1 -Kit base-kit -DryRun
    .\publish-stackkit.ps1 -Kit modern-homelab -SkipValidation
    .\publish-stackkit.ps1 -Kit none  # sync shared only, no kit
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("base-kit", "modern-homelab", "ha-kit", "none")]
    [string]$Kit,

    [switch]$DryRun,
    [switch]$SkipValidation,
    [switch]$SkipShared,

    [string]$DevRepo = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [string]$PubRepo = (Resolve-Path (Join-Path $PSScriptRoot "..\..\stackKits"))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Configuration -----------------------------------------------------------

# Directories to mirror (source relative path -> same in target)
# These are synced with robocopy /MIR
$SharedDirs = @(
    "base"
    "platforms"
    "pkg"
    "cue.mod"
    "tests"
)

# Directories that need subdirectory-level exclusions
$ExcludedCmdDirs    = @("stackkit-server")   # cmd/ children to exclude
$ExcludedInternalDirs = @("api")             # internal/ children to exclude

# Root files to sync (everything else at root is internal-only)
$RootFiles = @(
    "go.mod"
    "go.sum"
    "Makefile"
    "LICENSE"
    "CONTRIBUTING.md"
    "mise.toml"
    "stack-spec.yaml"
)
# NOTE: README.md is NOT synced — the public repo has its own custom README.

# Public docs whitelist (everything else in docs/ is internal)
$PublicDocs = @(
    "ARCHITECTURE_V4.md"
    "CHANGELOG.md"
    "CLI.md"
    "creating-stackkits.md"
    "DEPLOYMENT.md"
    "DEVELOPMENT.md"
    "IDENTITY-PLATFORM.md"
    "README.md"
    "ROADMAP.md"
    "stack-spec-reference.md"
    "TESTING.md"
)

# --- Helpers ------------------------------------------------------------------

function Write-Header([string]$msg) {
    Write-Host ""
    Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Write-Step([string]$msg) {
    Write-Host "  -> $msg" -ForegroundColor Gray
}

function Write-Ok([string]$msg) {
    Write-Host "  OK $msg" -ForegroundColor Green
}

function Write-Warn([string]$msg) {
    Write-Host "  !! $msg" -ForegroundColor Yellow
}

function Write-Fail([string]$msg) {
    Write-Host "  FAIL $msg" -ForegroundColor Red
}

function Invoke-Robocopy {
    param(
        [string]$Source,
        [string]$Dest,
        [string[]]$ExcludeDirs = @(),
        [switch]$IsDryRun
    )

    $args_ = @($Source, $Dest, "/MIR", "/NJH", "/NJS", "/NDL", "/NP")

    if ($ExcludeDirs.Count -gt 0) {
        $args_ += "/XD"
        foreach ($d in $ExcludeDirs) {
            $args_ += (Join-Path $Source $d)
        }
    }

    # Exclude .git directories everywhere
    if ($args_ -notcontains "/XD") {
        $args_ += "/XD"
    }
    $args_ += ".git"

    if ($IsDryRun) {
        $args_ += "/L"
    }

    $output = & robocopy @args_ 2>&1
    $rc = $LASTEXITCODE

    # Robocopy exit codes:
    #   0 = no changes
    #   1 = files copied
    #   2 = extra files/dirs in dest (would be purged with /MIR)
    #   3 = 1+2
    #   4 = mismatched files
    #   5-7 = combinations
    #   8+ = errors
    if ($rc -ge 8) {
        Write-Fail "robocopy failed (exit $rc) syncing $Source"
        $output | ForEach-Object { Write-Host "    $_" }
        throw "robocopy error syncing $Source -> $Dest"
    }

    # Exit code 1-7 means there were changes; 0 means no changes
    # Use exit code rather than parsing locale-dependent output text
    if ($rc -gt 0) {
        return $rc  # non-zero = changes detected
    }
    return 0
}

# --- Pre-flight checks --------------------------------------------------------

Write-Header "Pre-flight checks"

if (-not (Test-Path (Join-Path $DevRepo ".git"))) {
    throw "Dev repo not found or not a git repo: $DevRepo"
}
if (-not (Test-Path (Join-Path $PubRepo ".git"))) {
    throw "Public repo not found or not a git repo: $PubRepo"
}

Write-Step "Dev repo:    $DevRepo"
Write-Step "Public repo: $PubRepo"
Write-Step "Kit:         $Kit"
Write-Step "Dry run:     $DryRun"

if ($Kit -ne "none" -and -not (Test-Path (Join-Path $DevRepo $Kit))) {
    throw "Kit directory not found: $(Join-Path $DevRepo $Kit)"
}

# Check for uncommitted changes in dev repo
$devStatus = git -C $DevRepo status --porcelain 2>&1
if ($devStatus) {
    Write-Warn "Dev repo has uncommitted changes — syncing working tree as-is"
}

# --- Sync shared components ---------------------------------------------------

$totalChanges = 0

if (-not $SkipShared) {
    Write-Header "Syncing shared components"

    # 1. Mirror shared directories
    foreach ($dir in $SharedDirs) {
        $src = Join-Path $DevRepo $dir
        $dst = Join-Path $PubRepo $dir
        if (-not (Test-Path $src)) {
            Write-Warn "Skipping missing dir: $dir"
            continue
        }
        Write-Step "Syncing $dir/"
        $n = Invoke-Robocopy -Source $src -Dest $dst -IsDryRun:$DryRun
        if ($n -gt 0) { Write-Ok "changes detected"; $totalChanges++ } else { Write-Ok "up to date" }
    }

    # 2. cmd/ with exclusions (skip stackkit-server)
    Write-Step "Syncing cmd/ (excluding: $($ExcludedCmdDirs -join ', '))"
    $n = Invoke-Robocopy -Source (Join-Path $DevRepo "cmd") -Dest (Join-Path $PubRepo "cmd") `
         -ExcludeDirs $ExcludedCmdDirs -IsDryRun:$DryRun
    if ($n -gt 0) { Write-Ok "changes detected"; $totalChanges++ } else { Write-Ok "up to date" }

    # 3. internal/ with exclusions (skip api)
    Write-Step "Syncing internal/ (excluding: $($ExcludedInternalDirs -join ', '))"
    $n = Invoke-Robocopy -Source (Join-Path $DevRepo "internal") -Dest (Join-Path $PubRepo "internal") `
         -ExcludeDirs $ExcludedInternalDirs -IsDryRun:$DryRun
    if ($n -gt 0) { Write-Ok "changes detected"; $totalChanges++ } else { Write-Ok "up to date" }

    # 4. Root files (selective copy)
    Write-Step "Syncing root files"
    $rootChanges = 0
    foreach ($f in $RootFiles) {
        $src = Join-Path $DevRepo $f
        $dst = Join-Path $PubRepo $f
        if (-not (Test-Path $src)) {
            Write-Warn "Root file missing in dev: $f"
            continue
        }

        $needsCopy = $false
        if (-not (Test-Path $dst)) {
            $needsCopy = $true
        } else {
            # Compare hash
            $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
            $needsCopy = ($srcHash -ne $dstHash)
        }

        if ($needsCopy) {
            if (-not $DryRun) {
                Copy-Item -Path $src -Destination $dst -Force
            }
            Write-Ok "$f ($(if ($DryRun) {'would update'} else {'updated'}))"
            $rootChanges++
        }
    }
    if ($rootChanges -eq 0) { Write-Ok "Root files up to date" }
    if ($rootChanges -gt 0) { $totalChanges++ }

    # 5. Docs (whitelist approach)
    Write-Header "Syncing docs (public subset)"

    # Sync ADR subdirectory fully
    $adrSrc = Join-Path $DevRepo "docs\ADR"
    $adrDst = Join-Path $PubRepo "docs\ADR"
    if (Test-Path $adrSrc) {
        Write-Step "Syncing docs/ADR/"
        $n = Invoke-Robocopy -Source $adrSrc -Dest $adrDst -IsDryRun:$DryRun
        if ($n -gt 0) { Write-Ok "changes detected"; $totalChanges++ } else { Write-Ok "up to date" }
    }

    # Copy individual public docs
    $docChanges = 0
    foreach ($doc in $PublicDocs) {
        $src = Join-Path $DevRepo "docs\$doc"
        $dst = Join-Path $PubRepo "docs\$doc"
        if (-not (Test-Path $src)) { continue }

        $needsCopy = $false
        if (-not (Test-Path $dst)) {
            $needsCopy = $true
        } else {
            $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
            $needsCopy = ($srcHash -ne $dstHash)
        }

        if ($needsCopy) {
            if (-not $DryRun) {
                Copy-Item -Path $src -Destination $dst -Force
            }
            Write-Ok "docs/$doc ($(if ($DryRun) {'would update'} else {'updated'}))"
            $docChanges++
        }
    }
    if ($docChanges -eq 0) { Write-Ok "Docs up to date" }
    if ($docChanges -gt 0) { $totalChanges++ }

    # Clean stale docs: remove docs in public that are NOT in the whitelist and NOT in ADR/
    $pubDocs = Get-ChildItem (Join-Path $PubRepo "docs") -File -ErrorAction SilentlyContinue
    foreach ($existing in $pubDocs) {
        if ($existing.Name -notin $PublicDocs) {
            Write-Warn "Stale doc in public repo: docs/$($existing.Name)"
            if (-not $DryRun) {
                Remove-Item $existing.FullName -Force
                Write-Ok "Removed docs/$($existing.Name)"
            } else {
                Write-Ok "Would remove docs/$($existing.Name)"
            }
            $totalChanges++
        }
    }
}


# --- Sync StackKit directory --------------------------------------------------

if ($Kit -ne "none") {
    Write-Header "Syncing StackKit: $Kit"
    $kitSrc = Join-Path $DevRepo $Kit
    $kitDst = Join-Path $PubRepo $Kit

    $n = Invoke-Robocopy -Source $kitSrc -Dest $kitDst -IsDryRun:$DryRun
    if ($n -gt 0) { Write-Ok "changes detected"; $totalChanges++ } else { Write-Ok "up to date" }
}

# --- Validation ---------------------------------------------------------------

if (-not $SkipValidation -and -not $DryRun) {
    Write-Header "Post-sync validation"

    # CUE validation
    Write-Step "Running: cue vet ./..."
    Push-Location $PubRepo
    try {
        $cueOutput = cue vet ./... 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "CUE validation failed:"
            $cueOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            Pop-Location
            throw "CUE validation failed in public repo"
        }
        Write-Ok "CUE validation passed"
    } catch [System.Management.Automation.CommandNotFoundException] {
        Write-Warn "cue not found in PATH, skipping CUE validation"
    }

    # Go build
    Write-Step "Running: go build ./cmd/stackkit/"
    try {
        $goExe = "D:\DevTools\mise\installs\go\1.24.13\bin\go.exe"
        if (-not (Test-Path $goExe)) {
            $goExe = "go" # fall back to PATH
        }
        $buildOutput = & $goExe build -o (Join-Path $PubRepo "build\stackkit-check.exe") ./cmd/stackkit/ 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Go build failed:"
            $buildOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            Pop-Location
            throw "Go build failed in public repo"
        }
        # Clean up validation binary
        $checkBin = Join-Path $PubRepo "build\stackkit-check.exe"
        if (Test-Path $checkBin) { Remove-Item $checkBin -Force }
        $buildDir = Join-Path $PubRepo "build"
        if ((Test-Path $buildDir) -and @(Get-ChildItem $buildDir -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item $buildDir -Force
        }
        Write-Ok "Go build passed"
    } catch [System.Management.Automation.CommandNotFoundException] {
        Write-Warn "go not found, skipping build validation"
    }

    Pop-Location
}

# --- Summary ------------------------------------------------------------------

Write-Header "Summary"

if ($DryRun) {
    Write-Host "  DRY RUN — no files were changed" -ForegroundColor Yellow
    if ($totalChanges -gt 0) {
        Write-Host "  $totalChanges component(s) have pending changes" -ForegroundColor Yellow
    } else {
        Write-Host "  Everything up to date" -ForegroundColor Green
    }
} else {
    if ($totalChanges -gt 0) {
        Write-Host "  $totalChanges component(s) synced" -ForegroundColor Green
    } else {
        Write-Host "  Everything already up to date" -ForegroundColor Green
    }
    if (-not $SkipValidation) {
        Write-Host "  Validation: PASSED" -ForegroundColor Green
    }
}

# Show git status of public repo
Write-Host ""
Write-Step "Public repo git status:"
$pubStatus = git -C $PubRepo status --short 2>&1
if ($pubStatus) {
    $pubStatus | ForEach-Object { Write-Host "    $_" }
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "    cd $PubRepo"
    Write-Host "    git diff                  # review changes"
    Write-Host "    git add -A"
    Write-Host '    git commit -m "Sync <kit> from dev"'
    Write-Host "    git push"
} else {
    Write-Ok "Public repo is clean — nothing to commit"
}

Write-Host ""
