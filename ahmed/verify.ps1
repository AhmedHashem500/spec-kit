# verify.ps1 : prove the Ahmed extension + preset still work against this fork's spec-kit.
#
# Windows PowerShell 5.1 safe: ASCII only, no ?. / ?? / ternary operators.
#
# What it does (each step exits 1 on failure):
#   1. Makes sure the fork's .venv exists and has the fork installed editable (uv).
#   2. Drift guard: the owner-rules block copied into commands/speckit.implement.md
#      must equal commands/owner-rules.md.
#   3. Runs the upstream pytest files for extensions, presets and hooks.
#   4. Smoke test in a fresh folder, two install routes:
#        A) specify init, then "extension add --dev" + "preset add --dev"
#        B) specify init --extension <path> --preset <path>
#      and checks the generated Claude skills, hooks and constitution template.
#
# Usage:
#   powershell -NoProfile -File ahmed\verify.ps1 [-WorkDir <folder>] [-SkipTests] [-KeepWorkDir]
param(
  [string]$WorkDir = (Join-Path $env:TEMP 'speckit-ahmed-verify'),
  [switch]$SkipTests,
  [switch]$KeepWorkDir
)
$ErrorActionPreference = 'Stop'

$fork = Split-Path -Parent $PSScriptRoot
$venvPy = Join-Path $fork '.venv\Scripts\python.exe'
$specify = Join-Path $fork '.venv\Scripts\specify.exe'
$extDir = Join-Path $PSScriptRoot 'extension'
$presetDir = Join-Path $PSScriptRoot 'preset'
$script:failures = 0

# Rich output from specify must not crash on a cp1252 console.
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
# The project scripts look for python3 first; on Windows that can be the
# Microsoft Store stub. Point them at the fork's interpreter instead.
$env:SPECKIT_PYTHON_EXECUTABLE = $venvPy

function Write-Check([bool]$ok, [string]$label) {
  if ($ok) { Write-Output "PASS  $label" } else { Write-Output "FAIL  $label"; $script:failures++ }
}

function Read-Utf8([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Test-FileText([string]$path, [string]$needle, [string]$label) {
  $text = Read-Utf8 $path
  $ok = ($null -ne $text) -and $text.Contains($needle)
  Write-Check $ok "$label  [$needle]"
}

# --- 1. venv -----------------------------------------------------------------
if (-not (Test-Path -LiteralPath $venvPy)) {
  Write-Output "creating .venv with uv"
  uv venv (Join-Path $fork '.venv') --python 3.14 -q
  if ($LASTEXITCODE -ne 0) { throw "uv venv failed" }
}
Push-Location $fork
try {
  uv pip install --python $venvPy -e ".[test]" -q
  if ($LASTEXITCODE -ne 0) { throw "uv pip install of the fork failed" }
} finally { Pop-Location }
$ver = (& $specify --version) -join ' '
Write-Output "specify under test: $ver"

# --- 2. drift guard ----------------------------------------------------------
$rules = (Read-Utf8 (Join-Path $presetDir 'commands\owner-rules.md')).Trim()
$impl = Read-Utf8 (Join-Path $presetDir 'commands\speckit.implement.md')
Write-Check ($impl.Contains($rules)) "preset implement block carries an exact copy of owner-rules.md"

# --- 3. upstream tests -------------------------------------------------------
if (-not $SkipTests) {
  $tests = @(
    'tests/test_extensions.py',
    'tests/test_presets.py',
    'tests/test_extension_skills.py',
    'tests/test_extension_registration.py',
    'tests/test_command_template_hooks.py',
    'tests/test_ps1_encoding.py'
  )
  # PS 5.1 turns redirected native stderr into terminating errors under 'Stop'.
  $ErrorActionPreference = 'Continue'
  Push-Location $fork
  try {
    $out = & $venvPy -m pytest @tests -q -n auto -p no:cacheprovider 2>&1
    $code = $LASTEXITCODE
  } finally { Pop-Location; $ErrorActionPreference = 'Stop' }
  $summary = ($out | Where-Object { "$_" -match '(passed|failed|error)' } | Select-Object -Last 1)
  Write-Output "pytest: $summary"
  Write-Check ($code -eq 0) "upstream extension/preset/hook tests (exit $code)"
}

# --- 4. smoke ----------------------------------------------------------------
$runDir = Join-Path $WorkDir ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Write-Output "smoke folder: $runDir"

function Invoke-Specify([string]$cwd, [string[]]$cliArgs) {
  $ErrorActionPreference = 'Continue'  # function scope only; see the pytest note above
  Push-Location $cwd
  try {
    $log = & $specify @cliArgs 2>&1
    $code = $LASTEXITCODE
  } finally { Pop-Location }
  if ($code -ne 0) {
    $log | Select-Object -Last 15 | ForEach-Object { Write-Output "    $_" }
    throw "specify $($cliArgs -join ' ') failed (exit $code)"
  }
}

function Test-Project([string]$proj, [string]$route) {
  $skills = Join-Path $proj '.claude\skills'
  $impl = Join-Path $skills 'speckit-implement\SKILL.md'
  Test-FileText $impl 'ahmed-preset:implement-gate' "$route implement skill has the gate"
  Test-FileText $impl 'external-review/APPROVED.md' "$route implement gate checks APPROVED.md"
  Test-FileText $impl '/speckit-ahmed-review-gate' "$route implement gate calls the review gate"
  Test-FileText $impl 'ahmed-preset:owner-rules' "$route implement skill has the owner rules"
  foreach ($cmd in @('specify', 'clarify', 'plan', 'tasks', 'checklist', 'analyze')) {
    Test-FileText (Join-Path $skills "speckit-$cmd\SKILL.md") 'Egyptian Arabic' "$route speckit-$cmd has the owner rules"
  }
  $gate = Join-Path $skills 'speckit-ahmed-review-gate\SKILL.md'
  Test-FileText $gate 'review-package.md' "$route review-gate skill exists"
  $flow = Join-Path $skills 'speckit-ahmed-flow\SKILL.md'
  Test-FileText $flow 'Stop points summary' "$route flow skill exists"
  $ErrorActionPreference = 'Continue'
  $hookMsg = (& $venvPy (Join-Path $PSScriptRoot 'check_hooks.py') $proj 2>&1) -join ' '
  Write-Check ($LASTEXITCODE -eq 0) "$route hook: $hookMsg"
  Push-Location $proj
  try {
    $resolved = (& powershell.exe -NoProfile -File '.specify\scripts\powershell\resolve-template.ps1' constitution-template -Json 2>&1) -join "`n"
  } finally { Pop-Location }
  Write-Check ($resolved.Contains('ahmed-preset:constitution') -and $resolved.Contains('Zero Cost')) "$route constitution-template resolves to the Ahmed principles"
}

$initArgs = @('--integration', 'claude', '--script', 'ps', '--non-interactive', '--ignore-agent-tools')

# Route A: existing project, add extension and preset afterwards.
Invoke-Specify $runDir (@('init', 'route-a') + $initArgs)
$projA = Join-Path $runDir 'route-a'
Invoke-Specify $projA @('extension', 'add', '--dev', $extDir)
Invoke-Specify $projA @('preset', 'add', '--dev', $presetDir)
Test-Project $projA 'A'

# Route B: new project, everything at init (copies files, seeds the constitution).
Invoke-Specify $runDir (@('init', 'route-b') + $initArgs + @('--extension', $extDir, '--preset', $presetDir))
$projB = Join-Path $runDir 'route-b'
Test-Project $projB 'B'
Test-FileText (Join-Path $projB '.specify\memory\constitution.md') 'ahmed-preset:constitution' 'B memory/constitution.md seeded from the Ahmed template'

if (-not $KeepWorkDir) { Remove-Item -LiteralPath $runDir -Recurse -Force }

if ($script:failures -gt 0) {
  Write-Output "VERIFY: FAIL ($($script:failures) check(s) failed)"
  exit 1
}
Write-Output "VERIFY: PASS"
exit 0
