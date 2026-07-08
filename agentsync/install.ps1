# AgentSync skill installer / updater (Windows PowerShell)
# Usage:
#   irm https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.ps1 | iex
#   irm .../install.ps1 | iex; Install-AgentSync -Agents grok,claude -Check

param(
    [string]$Agents = "",
    [switch]$Check,
    [string]$Branch = "main"
)

$Repo = "FeiZhuLulu/AgentSync"
$SkillUrl = "https://raw.githubusercontent.com/$Repo/$Branch/agentsync/SKILL.md"

function Get-SkillDir([string]$Agent) {
    switch ($Agent) {
        "claude"  { return Join-Path $env:USERPROFILE ".claude\skills\agentsync" }
        "grok"    { return Join-Path $env:USERPROFILE ".grok\skills\agentsync" }
        "cursor"  { return Join-Path $env:USERPROFILE ".cursor\skills\agentsync" }
        "opencode" { return Join-Path $env:USERPROFILE ".config\opencode\skills\agentsync" }
        default   { return $null }
    }
}

function Get-InstalledVersion([string]$Path) {
    if (-not (Test-Path $Path)) { return "not installed" }
    $line = Select-String -Path $Path -Pattern '^\s+version:' | Select-Object -First 1
    if ($line -match '"([^"]+)"') { return $Matches[1] }
    return "unknown"
}

function Get-RemoteVersion {
    $content = (Invoke-WebRequest -Uri $SkillUrl -UseBasicParsing).Content
    if ($content -match '(?m)^\s+version:\s+"([^"]+)"') { return $Matches[1] }
    return "unknown"
}

function Detect-Agents {
    $found = @()
    foreach ($a in @("claude", "grok", "cursor", "opencode")) {
        $dir = Get-SkillDir $a
        $parent = Split-Path $dir -Parent
        if ((Test-Path $parent) -or (Test-Path "$dir\SKILL.md")) {
            $found += $a
        }
    }
    if ($found.Count -eq 0) { return @("claude", "grok", "cursor") }
    return $found
}

$targets = if ($Agents) { $Agents -split ',' | ForEach-Object { $_.Trim() } } else { Detect-Agents }
$remoteVer = Get-RemoteVersion

if ($Check) {
    Write-Host "Latest: v$remoteVer ($Branch)"
    foreach ($a in $targets) {
        $dir = Get-SkillDir $a
        if (-not $dir) {
            Write-Host "  $a`: unsupported agent name"
            continue
        }
        $localVer = Get-InstalledVersion "$dir\SKILL.md"
        Write-Host "  $a`: $localVer -> $dir\SKILL.md"
    }
    return
}

Write-Host "Installing AgentSync v$remoteVer to: $($targets -join ', ')"

$content = (Invoke-WebRequest -Uri $SkillUrl -UseBasicParsing).Content
foreach ($a in $targets) {
    $dir = Get-SkillDir $a
    if (-not $dir) {
        Write-Warning "Skip unsupported agent: $a"
        continue
    }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $out = Join-Path $dir "SKILL.md"
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($out, $content, $utf8)
    Write-Host "  OK $a -> $out"
}

Write-Host "Done. Run /agentsync in your agent to use it."