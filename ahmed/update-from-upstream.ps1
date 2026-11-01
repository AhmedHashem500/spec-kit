# update-from-upstream.ps1 : merge an upstream spec-kit release into our fork, then verify.
#
# Our fork is D:\My Apps\Skills\spec-kit, a clone of github.com/github/spec-kit (remote "upstream";
# "origin" is AhmedHashem500/spec-kit). Our customisation lives only under ahmed\ (extension,
# preset, scripts), so upstream merges never touch it.
#   - Merges the latest release tag (vX.Y.Z, no pre-release) or -Tag into branch "ahmed".
#     MERGE only: never rebase, never reset, so our commits survive.
#   - If the branch already holds every code change of the tag (it tracks upstream main past the
#     release), nothing is merged: the release's own version-bump commit would only conflict.
#   - A merge conflict aborts the merge, leaves the branch as it was and exits 1 with the file list.
#   - After a merge (or when already up to date) it runs ahmed\verify.ps1: upstream extension /
#     preset tests plus a smoke install of our extension and preset. Exit code = verify's.
#   - Nothing is pushed. Push yourself after a PASS: git -C "<fork>" push origin ahmed
#
# Windows PowerShell 5.1 safe: ASCII only, no ?. / ?? / ternary operators.
#
# Usage:
#   powershell -NoProfile -File ahmed\update-from-upstream.ps1 [-Tag v1.2.6] [-SkipVerify]
param(
  [string]$Tag,
  [switch]$SkipVerify
)
$ErrorActionPreference = 'Stop'
$fork = Split-Path -Parent $PSScriptRoot
$branch = 'ahmed'

function Invoke-Git {
  # PS 5.1 turns git's stderr progress lines into errors under 'Stop'; check the exit code instead.
  $ErrorActionPreference = 'Continue'
  $out = & git -C $fork @args 2>&1
  $script:gitExit = $LASTEXITCODE
  return $out
}

if (-not (Test-Path -LiteralPath (Join-Path $fork '.git'))) { throw "fork missing: $fork" }
$current = ((Invoke-Git branch --show-current) -join '').Trim()
if ($current -ne $branch) { throw "fork is on '$current', expected '$branch'" }
$dirty = Invoke-Git status --porcelain
if ($dirty) { throw "fork has uncommitted changes; commit or revert them first" }

Invoke-Git fetch --quiet --tags upstream | Out-Null
if ($script:gitExit -ne 0) { throw "git fetch --tags upstream failed" }

if (-not $Tag) {
  $tags = Invoke-Git tag --list 'v*' --sort=-v:refname
  $Tag = $tags | Where-Object { "$_" -match '^v\d+\.\d+\.\d+$' } | Select-Object -First 1
  if (-not $Tag) { throw "no release tag (vX.Y.Z) found after fetching upstream" }
}
Invoke-Git rev-parse --verify --quiet "refs/tags/$Tag" | Out-Null
if ($script:gitExit -ne 0) { throw "tag not found: $Tag" }

# Upstream tags each release on a "chore: bump version" commit that branches off main, while
# main moves on (next .devN version). When the fork already holds main past that point, the only
# commits missing are release bookkeeping (pyproject.toml / CHANGELOG.md); merging them would just
# conflict on the version line, so treat the release as already contained.
$bookkeeping = @('pyproject.toml', 'CHANGELOG.md')
$missing = @(Invoke-Git rev-list "HEAD..refs/tags/$Tag" | Where-Object { "$_".Trim() })
$codeMissing = $false
foreach ($c in $missing) {
  $files = Invoke-Git diff-tree --no-commit-id --name-only -r "$c"
  foreach ($f in $files) { if ($bookkeeping -notcontains "$f".Trim()) { $codeMissing = $true } }
}
if ($missing.Count -eq 0) {
  Write-Output "upstream: $Tag already merged into $branch; nothing to merge"
} elseif (-not $codeMissing) {
  Write-Output "upstream: $branch already contains the code of $Tag; only release bookkeeping ($($bookkeeping -join ', ')) differs; nothing to merge"
} else {
  $incoming = ((Invoke-Git rev-list --count "HEAD..refs/tags/$Tag") -join '').Trim()
  Invoke-Git merge --no-edit --no-ff -m "Merge upstream release $Tag into $branch" "refs/tags/$Tag" | Out-Null
  if ($script:gitExit -ne 0) {
    $conflicts = Invoke-Git diff --name-only --diff-filter=U
    Invoke-Git merge --abort | Out-Null
    Write-Output "MERGE CONFLICT merging $Tag ($incoming new commits). Merge aborted; branch $branch is unchanged."
    Write-Output "Conflicting files: $($conflicts -join ', ')"
    Write-Output "Resolve by hand: git -C `"$fork`" merge $Tag, fix the files, commit, then re-run this script."
    exit 1
  }
  Write-Output "upstream: merged $Tag ($incoming new commits) into $branch"
  $outside = Invoke-Git diff --name-only 'HEAD^1' HEAD -- ahmed
  if ($outside) { Write-Output "WARNING: the merge changed files under ahmed\: $($outside -join ', ')" }
}

if ($SkipVerify) { Write-Output "verification skipped (-SkipVerify)"; exit 0 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify.ps1')
$code = $LASTEXITCODE
if ($code -ne 0) {
  Write-Output "VERIFY FAILED after updating to $Tag. Nothing was pushed. To undo the merge, ask before running: git -C `"$fork`" reset --hard ORIG_HEAD"
}
exit $code
