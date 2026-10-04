$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent)).TrimEnd('\')
$runtimeDir = Join-Path $projectRoot '.runtime'
$servicePorts = @(8086, 5186)

function Import-LocalSettings {
    $settingsFile = Join-Path $projectRoot '.env'
    if (-not (Test-Path -LiteralPath $settingsFile)) { throw '.env がありません。.env.example から作成してください。' }
    foreach ($line in Get-Content -LiteralPath $settingsFile) {
        if ($line -match '^([A-Z][A-Z0-9_]*)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

function Get-JavaExecutable {
    # The Oracle PATH launcher can spawn a second JVM. Start the actual JDK binary.
    $probe = New-Object System.Diagnostics.Process
    $probe.StartInfo.FileName = (Get-Command java.exe).Source
    $probe.StartInfo.Arguments = '-XshowSettings:properties -version'
    $probe.StartInfo.UseShellExecute = $false
    $probe.StartInfo.CreateNoWindow = $true
    $probe.StartInfo.RedirectStandardError = $true
    $null = $probe.Start()
    $settings = $probe.StandardError.ReadToEnd()
    $probe.WaitForExit()
    $javaMatch = [regex]::Match($settings, '(?m)^\s*java.home = (.+)\r?$')
    if (-not $javaMatch.Success) { throw 'Java の実行ファイルを特定できません。' }
    $executable = Join-Path $javaMatch.Groups[1].Value.Trim() 'bin\java.exe'
    if (-not (Test-Path -LiteralPath $executable)) { throw 'Java の実行ファイルが見つかりません。' }
    return $executable
}

function Get-OwnedServiceProcesses {
    $apiMarker = (Join-Path $projectRoot 'backend\target\kusakari-api-0.1.0.jar').ToLowerInvariant()
    $webMarker = (Join-Path $projectRoot 'node_modules\vite\bin\vite.js').ToLowerInvariant()
    @(Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='node.exe'" | ForEach-Object {
        $command = ([string]$_.CommandLine).Replace('/', '\').ToLowerInvariant()
        $kind = if ($_.Name -ieq 'java.exe' -and $command.Contains($apiMarker)) { 'Api' }
            elseif ($_.Name -ieq 'node.exe' -and $command.Contains($webMarker)) { 'Web' }
            else { $null }
        if ($kind) {
            [pscustomobject]@{
                Id = [int]$_.ProcessId
                Created = $_.CreationDate.ToUniversalTime().ToString('o')
                Kind = $kind
            }
        }
    })
}

function Test-OwnedServiceProcess($record) {
    if (-not $record) { return $false }
    $current = @(Get-OwnedServiceProcesses | Where-Object {
        $_.Id -eq $record.Id -and $_.Created -eq $record.Created -and $_.Kind -eq $record.Kind
    })
    return $current.Count -eq 1
}

function Stop-OwnedServices {
    $deadline = (Get-Date).AddSeconds(20)
    do {
        $owned = @(Get-OwnedServiceProcesses)
        if ($owned.Count -eq 0) { return }
        foreach ($record in $owned) {
            if (-not (Test-OwnedServiceProcess $record)) { continue }
            $process = Get-Process -Id $record.Id -ErrorAction SilentlyContinue
            if (-not $process) { continue }
            Stop-Process -Id $record.Id -Force -ErrorAction Stop
            if (-not $process.WaitForExit(5000)) { throw "Kusakari $($record.Kind) を停止できません (PID $($record.Id))。" }
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)
    throw 'Kusakari の Web/API プロセスが残っています。'
}

function Assert-PortsAvailable {
    foreach ($port in $servicePorts) {
        $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue)
        if ($listeners.Count -gt 0) {
            $ids = ($listeners | Select-Object -ExpandProperty OwningProcess -Unique) -join ','
            throw "固定ポート $port は別プロセスが使用中です (PID $ids)。対象を確認してください。代替ポートでは起動しません。"
        }
    }
}

function Wait-Endpoint([string]$url, [int]$seconds = 60) {
    $deadline = (Get-Date).AddSeconds($seconds)
    do {
        try { return Invoke-RestMethod -Uri $url -TimeoutSec 2 }
        catch { Start-Sleep -Milliseconds 500 }
    } while ((Get-Date) -lt $deadline)
    throw "起動確認がタイムアウトしました: $url。 .runtime のログを確認してください。"
}

function Assert-ServicesHealthy {
    $api = Wait-Endpoint 'http://127.0.0.1:8086/api/health' 60
    if ($api.application -ne 'kusakari' -or $api.backend -ne 'spring-boot') { throw 'API の応答元が Kusakari ではありません。' }
    $page = Wait-Endpoint 'http://127.0.0.1:5186/' 30
    if ([string]$page -notlike '*Kusakari*') { throw 'Web 画面の応答元が Kusakari ではありません。' }
    $proxy = Wait-Endpoint 'http://127.0.0.1:5186/api/health' 15
    if ($proxy.application -ne 'kusakari') { throw 'Web から API への接続が機能していません。' }
}
