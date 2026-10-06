param([switch]$SkipInstall)

. "$PSScriptRoot\common.ps1"
$setupScript = Join-Path $projectRoot 'scripts\setup-existing-mysql.ps1'
if ($SkipInstall) {
    & $setupScript -SkipInstall
} else {
    & $setupScript
}
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
