param([switch]$SkipInstall)
. "$PSScriptRoot\common.ps1"
Import-LocalSettings
Set-Location $projectRoot
$mysql = Get-Command mysql.exe -ErrorAction SilentlyContinue
$mysqlPath = if ($mysql) { $mysql.Source } else { 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' }
if (-not (Test-Path -LiteralPath $mysqlPath)) { throw 'MySQL client is required. Add mysql.exe to PATH.' }
if (-not $env:KUSAKARI_ADMIN_PASSWORD) {
    $credential = New-Object System.Management.Automation.PSCredential('root',(Read-Host 'MySQL root password' -AsSecureString))
    $env:KUSAKARI_ADMIN_PASSWORD = $credential.GetNetworkCredential().Password
}
if ($env:KUSAKARI_DB_USER -ne 'kusakari') { throw 'This setup provisions only the kusakari database user.' }
if ($env:KUSAKARI_DB_PASSWORD -notmatch '^[A-Za-z0-9_!@#%+=.-]{1,128}$') { throw 'Use 1-128 letters, numbers, or _!@#%+=.- for the local DB password.' }
$env:MYSQL_PWD = $env:KUSAKARI_ADMIN_PASSWORD
try {
    $sql = @"
CREATE DATABASE IF NOT EXISTS kusakari CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE IF NOT EXISTS kusakari_e2e CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS 'kusakari'@'localhost' IDENTIFIED BY '$($env:KUSAKARI_DB_PASSWORD)';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,ALTER,DROP,INDEX,REFERENCES ON kusakari.* TO 'kusakari'@'localhost';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,ALTER,DROP,INDEX,REFERENCES ON kusakari_e2e.* TO 'kusakari'@'localhost';
"@
    $sql | & $mysqlPath -h 127.0.0.1 -u root --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw 'MySQL provisioning failed.' }
} finally { Remove-Item Env:MYSQL_PWD, Env:KUSAKARI_ADMIN_PASSWORD -ErrorAction SilentlyContinue }
if (-not $SkipInstall) {
    & npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'npm ci failed.' }
    & npm.cmd run build:api
    if ($LASTEXITCODE -ne 0) { throw 'API build failed.' }
    & npm.cmd run build:web
    if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }
    & npx.cmd playwright install chromium
    if ($LASTEXITCODE -ne 0) { throw 'Browser install failed.' }
    & (Join-Path $projectRoot 'sysover-ray2\setup.ps1')
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'SysOverRay build failed.' }
}
Write-Host 'Setup complete. Run start.bat.'
