#Requires -Version 5.1
<#
.SYNOPSIS
  Delete failed GitHub Actions workflow runs (keeps successful / green runs).

.DESCRIPTION
  Uses GitHub CLI. Install from https://cli.github.com/ then run once:
    & "$env:ProgramFiles\GitHub CLI\gh.exe" auth login

  Default repo: Raven3DTech/R3DTOS-PI5
  Deletes runs with conclusion: failure, startup_failure, timed_out
#>
param(
  [string]$Repo = "Raven3DTech/R3DTOS-PI5",
  [int]$Limit = 500,
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$GH = Join-Path ${env:ProgramFiles} "GitHub CLI\gh.exe"
if (-not (Test-Path $GH)) {
  $GH = "gh"
}

$env:GH_PROMPT_DISABLED = "1"

& $GH auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "Not logged in. Run: & '$GH' auth login"
  exit 1
}

$bad = @("failure", "startup_failure", "timed_out")
$all = @()

foreach ($s in $bad) {
  $json = & $GH run list -R $Repo -L $Limit -s $s --json databaseId,conclusion,displayTitle,workflowName,createdAt 2>&1
  if ($LASTEXITCODE -ne 0) { continue }
  $runs = @($json | ConvertFrom-Json)
  if ($runs.Count -gt 0) { $all += $runs }
}

$ids = $all | Sort-Object databaseId -Unique
if (-not $ids -or $ids.Count -eq 0) {
  Write-Host "No failed runs found (failure / startup_failure / timed_out) in last $Limit per status."
  exit 0
}

Write-Host "Found $($ids.Count) failed run(s) to remove."
foreach ($r in $ids) {
  $line = "$($r.workflowName) #$($r.databaseId) $($r.displayTitle)"
  if ($WhatIf) {
    Write-Host "[WhatIf] Would delete: $line"
    continue
  }
  Write-Host "Deleting: $line"
  & $GH run delete $r.databaseId -R $Repo
}
Write-Host "Done."
