# PHASE-6 E2E preparation: copy fixtures to disposable scratch repos.
# Run from anywhere: powershell -File evaluation\e2e-2026-07\prep.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSCommandPath

foreach ($run in "run-a", "run-b") {
  $dst = Join-Path $root "scratch\$run"
  if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
  New-Item -ItemType Directory -Force $dst | Out-Null
  Copy-Item -Recurse -Force (Join-Path $root "fixtures\$run\*") $dst
  git -C $dst init -q
  git -C $dst add -A
  git -C $dst commit -q -m "fixture baseline"
  Write-Host "prepared: $dst"
}

Write-Host ""
Write-Host "Baseline check (run-a should FAIL 1 of 3, run-b should FAIL its single test):"
foreach ($run in "run-a", "run-b") {
  $dst = Join-Path $root "scratch\$run"
  Push-Location $dst
  $out = & npm test 2>&1 | Select-String -Pattern "tests |pass |fail " | ForEach-Object { $_.Line.Trim() }
  Pop-Location
  Write-Host ("  {0}: {1}" -f $run, ($out -join " / "))
}
Write-Host ""
Write-Host "Next: follow handoff/PHASE-6-real-goal-e2e.md section 3 (start Claude Code inside scratch\run-a)."
