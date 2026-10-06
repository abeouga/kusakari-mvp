param(
    [switch]$NoBrowser,
    [switch]$NoOverlay
)

. "$PSScriptRoot\common.ps1"
$startScript = Join-Path $projectRoot 'scripts\start-existing-mysql.ps1'
if ($NoBrowser -and $NoOverlay) {
    & $startScript -NoBrowser -NoOverlay
} elseif ($NoBrowser) {
    & $startScript -NoBrowser
} elseif ($NoOverlay) {
    & $startScript -NoOverlay
} else {
    & $startScript
}
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
