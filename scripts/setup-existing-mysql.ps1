param(
    [switch]$SkipInstall
)

# This entry point is for PCs where MySQL Server is already installed.
# The root password is intentionally fixed by the project convention and is
# never written to .env or a log file.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\database.ps1"

function Get-InstalledMySqlServices {
    @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object {
        $path = [string]$_.PathName
        $_.Name -match '(?i)mysql|maria' -or
        $_.DisplayName -match '(?i)mysql|maria' -or
        $path -match '(?i)\\mysqld(?:\.exe)?(?:[" ]|$)'
    })
}

function Get-InstalledMySqlBin {
    foreach ($service in @(Get-InstalledMySqlServices)) {
        $path = [string]$service.PathName
        $match = [regex]::Match($path, '^\s*"([^"]*mysqld\.exe)"', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $match.Success) {
            $match = [regex]::Match($path, '^\s*([^ ]*mysqld\.exe)', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
        if (-not $match.Success) { continue }
        $bin = Split-Path -Parent $match.Groups[1].Value
        if ((Test-Path -LiteralPath (Join-Path $bin 'mysqld.exe')) -and
            (Test-Path -LiteralPath (Join-Path $bin 'mysql.exe'))) {
            return [IO.Path]::GetFullPath($bin).TrimEnd('\')
        }
    }
    return $null
}

function Start-InstalledMySql {
    if (Test-LocalPort 3306) {
        Write-Host '既存MySQLのTCP 3306を検出しました。'
        return
    }

    $services = @(Get-InstalledMySqlServices)
    if ($services.Count -eq 0) {
        throw 'MySQLサービスが見つかりません。MySQL Serverをサービスとしてインストールし、再実行してください。'
    }

    $started = $false
    foreach ($service in $services) {
        if ($service.State -ne 'Running') {
            Write-Host "MySQLサービスを起動します: $($service.Name)"
            try {
                Start-Service -Name $service.Name -ErrorAction Stop
            } catch {
                throw "MySQLサービス $($service.Name) を起動できません。管理者権限で実行するか、サービスを手動起動してください。"
            }
        }
        $started = $true
        $deadline = (Get-Date).AddSeconds(30)
        do {
            if (Test-LocalPort 3306) {
                Write-Host '既存MySQLのTCP 3306が利用可能です。'
                return
            }
            Start-Sleep -Milliseconds 500
        } while ((Get-Date) -lt $deadline)
    }

    if ($started) {
        throw 'MySQLサービスは起動しましたが、TCP 3306で接続できません。MySQLのエラーログを確認してください。'
    }
    throw 'MySQLの起動を確認できません。'
}

try {
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    Set-Location $projectRoot
    $env:KUSAKARI_EXISTING_MYSQL_ONLY = '1'
    $installedBin = Get-InstalledMySqlBin
    if ($installedBin) {
        $env:KUSAKARI_EXISTING_MYSQL_BIN = $installedBin
        Write-Host "既存MySQLの実行ファイルを使用します: $installedBin"
    }
    Start-InstalledMySql

    # database.ps1 uses this only for this invocation, so no root secret is
    # persisted. The application user is also provisioned with password.
    $env:KUSAKARI_EXISTING_MYSQL_PASSWORD = 'password'
    $setupScript = Join-Path $PSScriptRoot 'setup.ps1'
    if ($SkipInstall) {
        & $setupScript -DatabaseMode existing -Reconfigure -SkipInstall
    } else {
        & $setupScript -DatabaseMode existing -Reconfigure
    }
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} catch {
    Write-Error $_.Exception.Message
    exit 1
} finally {
    Remove-Item Env:KUSAKARI_EXISTING_MYSQL_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:KUSAKARI_EXISTING_MYSQL_BIN -ErrorAction SilentlyContinue
    Remove-Item Env:KUSAKARI_EXISTING_MYSQL_ONLY -ErrorAction SilentlyContinue
}
