. "$PSScriptRoot\common.ps1"
Stop-OwnedServices
$stateFile = Join-Path $runtimeDir 'processes.json'
if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile }
Assert-PortsAvailable
Write-Host 'Kusakari の Web/API を停止しました。固定ポート 5186 / 8086 は空いています。'
