. "$PSScriptRoot\mysql-tools.ps1"

function Set-PrivateFile([string]$path, [string]$content) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
    if (-not (Test-Path -LiteralPath $path)) { New-Item -ItemType File -Path $path -Force | Out-Null }
    $acl = [IO.File]::GetAccessControl($path, [Security.AccessControl.AccessControlSections]::Access)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) { $null = $acl.RemoveAccessRuleSpecific($rule) }
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'Allow')))
    [IO.File]::SetAccessControl($path, $acl)
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

function Read-Setting([string]$label, [string]$default) {
    $answer = Read-Host "$label [$default]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $default }
    return $answer.Trim()
}

function Read-Password([string]$label) {
    $secure = Read-Host $label -AsSecureString
    return (New-Object Management.Automation.PSCredential('input', $secure)).GetNetworkCredential().Password
}

function Invoke-MySql([string]$user, [string]$password, [int]$port, [string]$sql, [switch]$AllowFailure) {
    $options = Join-Path $runtimeDir ([guid]::NewGuid().ToString('N') + '.cnf')
    $escaped = $password.Replace('\','\\').Replace('"','\"').Replace("`r",'\r').Replace("`n",'\n')
    try {
        Set-PrivateFile $options "[client]`nhost=127.0.0.1`nport=$port`nuser=$user`npassword=`"$escaped`"`nprotocol=TCP`n"
        $process = New-Object Diagnostics.Process
        $process.StartInfo.FileName = Join-Path $mysqlBin 'mysql.exe'
        $process.StartInfo.Arguments = "--defaults-file=`"$options`" --default-character-set=utf8mb4 --batch --skip-column-names --connect-timeout=5"
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardInput = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $null = $process.Start()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($sql + "`n")
        $process.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $process.StandardInput.BaseStream.Flush()
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'MySQL操作がタイムアウトしました。' }
        $output = $outputTask.GetAwaiter().GetResult().Trim()
        $errorText = $errorTask.GetAwaiter().GetResult()
        $code = [regex]::Match($errorText, 'ERROR (\d+)').Groups[1].Value
        if ($process.ExitCode -ne 0 -and -not $AllowFailure) {
            $hint = switch ($code) {
                '1045' { 'ユーザー名・パスワードを確認してください。既存ユーザーのパスワードは変更しません。' }
                '1044' { '対象DBへの権限が不足しています。管理者ユーザーを確認してください。' }
                '2003' { 'MySQLの起動状態・ポートを確認してください。' }
                default { '接続設定・権限・DB構造を確認してください。' }
            }
            throw "MySQL処理失敗 (code $code)。$hint"
        }
        return [pscustomobject]@{ Success = $process.ExitCode -eq 0; Output = $output; Code = $code }
    } finally {
        if ($process) { $process.Dispose() }
        Remove-Item -LiteralPath $options -Force -ErrorAction SilentlyContinue
    }
}

function Test-LocalPort([int]$port) {
    $client = New-Object Net.Sockets.TcpClient
    try { $task = $client.ConnectAsync('127.0.0.1', $port); return $task.Wait(1000) -and $client.Connected }
    catch { return $false } finally { $client.Dispose() }
}

function Start-ManagedMySqlCore {
    $stateRoot = if ($env:KUSAKARI_MYSQL_HOME) { $env:KUSAKARI_MYSQL_HOME } else { Join-Path $env:LOCALAPPDATA 'Kusakari\mysql' }
    $stateFile = Join-Path $stateRoot 'instance.json'
    if (-not (Test-Path -LiteralPath $stateFile)) { throw '専用MySQLが未準備です。setup.batを実行してください。' }
    $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    if (-not $state.Ready) { throw '専用MySQLの初期化が未完了です。保存先を確認してください。空パスワードでは継続しません。' }
    if (Test-LocalPort $state.Port) {
        $result = Invoke-MySql 'root' (Get-ManagedPassword $stateRoot) $state.Port 'SELECT @@datadir;' -AllowFailure
        $actual = if ($result.Success) { [IO.Path]::GetFullPath($result.Output).TrimEnd('\') } else { '' }
        if ($actual -ine [IO.Path]::GetFullPath((Join-Path $stateRoot 'data')).TrimEnd('\')) { throw '専用MySQLのポートを別サーバーが使用中です。' }
        return $state
    }
    $config = Join-Path $stateRoot 'my.ini'
    $process = Start-Process -FilePath $state.Executable -ArgumentList "--defaults-file=`"$config`"" -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(40)
    do {
        if ($process.HasExited) { throw '専用MySQLが終了しました。Kusakari/mysqlのmysql-error.logを確認してください。' }
        if (Test-LocalPort $state.Port) { return $state }
        Start-Sleep -Milliseconds 300
    } while ((Get-Date) -lt $deadline)
    throw '専用MySQLの起動確認がタイムアウトしました。'
}

function Get-ManagedPassword([string]$directory) {
    $secure = Get-Content -Raw -LiteralPath (Join-Path $directory 'admin.secret') | ConvertTo-SecureString
    return (New-Object Management.Automation.PSCredential('root', $secure)).GetNetworkCredential().Password
}

function Initialize-ManagedMySqlCore([int]$port) {
    $stateRoot = if ($env:KUSAKARI_MYSQL_HOME) { $env:KUSAKARI_MYSQL_HOME } else { Join-Path $env:LOCALAPPDATA 'Kusakari\mysql' }
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    if (Test-Path -LiteralPath (Join-Path $stateRoot 'instance.json')) { return Start-ManagedMySqlCore }
    if (Test-LocalPort $port) { throw '専用MySQL用ポートが使用中です。空いているポートを指定してください。' }
    $data = Join-Path $stateRoot 'data'
    if (Test-Path -LiteralPath $data) { throw '初期化途中のMySQLデータがあります。既存データを自動削除しません。保存先を確認してください。' }
    $adminPassword = Read-Password '専用MySQL rootパスワード（新規作成・非表示）'
    if ([string]::IsNullOrEmpty($adminPassword)) { throw '専用MySQLのrootパスワードは空にできません。' }
    $secure = ConvertTo-SecureString $adminPassword -AsPlainText -Force
    Set-PrivateFile (Join-Path $stateRoot 'admin.secret') ($secure | ConvertFrom-SecureString)
    $ini = "[mysqld]`nbasedir=$((Split-Path $mysqlBin -Parent).Replace('\','/'))`ndatadir=$($data.Replace('\','/'))`nbind-address=127.0.0.1`nport=$port`nmysqlx=0`nskip-log-bin`nlog-error=$((Join-Path $stateRoot 'mysql-error.log').Replace('\','/'))`n"
    Set-PrivateFile (Join-Path $stateRoot 'my.ini') $ini
    $initialize = Start-Process -FilePath (Join-Path $mysqlBin 'mysqld.exe') -ArgumentList "--defaults-file=`"$stateRoot\my.ini`" --initialize-insecure" -WindowStyle Hidden -Wait -PassThru
    if ($initialize.ExitCode -ne 0) { throw 'MySQL初期化に失敗しました。mysql-error.logを確認してください。' }
    $state = @{ Executable = Join-Path $mysqlBin 'mysqld.exe'; Port = $port; Ready = $false }
    Set-PrivateFile (Join-Path $stateRoot 'instance.json') ($state | ConvertTo-Json)
    # The empty root credential is used only for this newly initialized instance.
    $process = Start-Process -FilePath $state.Executable -ArgumentList "--defaults-file=`"$stateRoot\my.ini`"" -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(40)
    while (-not (Test-LocalPort $port)) {
        if ($process.HasExited -or (Get-Date) -gt $deadline) {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
            throw '初期MySQL起動に失敗しました。'
        }
        Start-Sleep -Milliseconds 300
    }
    $literal = $adminPassword.Replace("'", "''")
    try { $null = Invoke-MySql 'root' '' $port "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES'; ALTER USER 'root'@'localhost' IDENTIFIED BY '$literal';" }
    catch { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }; throw }
    $state.Ready = $true
    Set-PrivateFile (Join-Path $stateRoot 'instance.json') ($state | ConvertTo-Json)
    return [pscustomobject]$state
}

function Invoke-ManagedLifecycle([int]$port, [switch]$Initialize) {
    $root = if ($env:KUSAKARI_MYSQL_HOME) { $env:KUSAKARI_MYSQL_HOME } else { Join-Path $env:LOCALAPPDATA 'Kusakari\mysql' }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    try { $lock = [IO.File]::Open((Join-Path $root 'instance.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
    catch { throw '専用MySQLを別プロセスが準備中です。終了後に再実行してください。' }
    try {
        if ($Initialize) { return Initialize-ManagedMySqlCore $port }
        return Start-ManagedMySqlCore
    } finally { $lock.Dispose() }
}

function Start-ManagedMySql { return Invoke-ManagedLifecycle }
function Initialize-ManagedMySql([int]$port) { return Invoke-ManagedLifecycle $port -Initialize }

function Initialize-Database([string]$mode, [switch]$reconfigure) {
    $settings = Join-Path $projectRoot '.env'
    if ((Test-Path -LiteralPath $settings) -and -not $reconfigure) {
        Import-LocalSettings
        $port = [int]$env:KUSAKARI_DB_PORT
        $script:mysqlBin = Get-KusakariMySqlBin -Portable:($env:KUSAKARI_DATABASE_MODE -eq 'managed')
        if ($env:KUSAKARI_DATABASE_MODE -eq 'managed') { $null = Start-ManagedMySql }
        $user = $env:KUSAKARI_DB_USER; $password = $env:KUSAKARI_DB_PASSWORD
        Write-Host '保存済みのDB接続設定を検証します。変更する場合は setup.bat -Reconfigure を実行してください。'
    } else {
        if ($mode -eq 'auto') { $mode = Read-Setting 'MySQL方式: existing=既存 / managed=Kusakari専用' 'existing' }
        if ($mode -notin @('existing','managed')) { throw 'MySQL方式はexistingまたはmanagedを指定してください。' }
        $script:mysqlBin = Get-KusakariMySqlBin -Portable:($mode -eq 'managed')
        if ($mode -eq 'managed') {
            Initialize-KusakariMySqlRuntime $mysqlBin
            $portText = Read-Setting '専用MySQLポート' '3307'
        } else {
            $hostName = Read-Setting 'MySQLホスト（ローカルデモ専用）' '127.0.0.1'
            if ($hostName -ne '127.0.0.1') { throw '接続先は127.0.0.1に限定しています。' }
            $portText = Read-Setting 'MySQLポート' '3306'
        }
        if ($portText -notmatch '^\d{1,5}$' -or [int]$portText -lt 1 -or [int]$portText -gt 65535) { throw 'ポートは1-65535の整数を入力してください。' }
        $port = [int]$portText
        if ($mode -eq 'managed') {
            $state = Initialize-ManagedMySql $port
            $port = [int]$state.Port; $adminUser = 'root'
            $stateRoot = if ($env:KUSAKARI_MYSQL_HOME) { $env:KUSAKARI_MYSQL_HOME } else { Join-Path $env:LOCALAPPDATA 'Kusakari\mysql' }
            $adminPassword = Get-ManagedPassword $stateRoot
        } else {
            $adminUser = Read-Setting 'MySQL管理者ユーザー' 'root'
            if ($adminUser -notmatch '^[A-Za-z0-9_]{1,32}$') { throw '管理者ユーザー名は英数字とアンダースコアで指定してください。' }
            $adminPassword = Read-Password 'MySQL管理者パスワード（非表示・保存しません）'
        }
        $null = Invoke-MySql $adminUser $adminPassword $port 'SELECT VERSION();'
        $user = Read-Setting 'Kusakariアプリ用DBユーザー（rootは不可）' 'kusakari'
        if ($user -notmatch '^[A-Za-z0-9_]{1,32}$' -or $user -eq 'root') { throw 'アプリ用ユーザーはroot以外の英数字とアンダースコアで指定してください。' }
        $password = Read-Password 'アプリ用DBパスワード（既存ユーザーは現在のパスワード）'
        if ($password.Length -lt 1 -or $password.Length -gt 128 -or $password -match "['\r\n\x00]") { throw 'アプリ用パスワードは1-128文字、単一引用符と改行を除いて指定してください。' }
        $count = (Invoke-MySql $adminUser $adminPassword $port "SELECT COUNT(*) FROM mysql.user WHERE User='$user';").Output
        if ([int]$count -gt 0) { $null = Invoke-MySql $user $password $port 'SELECT 1;' }
        # Reject unrelated existing schemas before provisioning users or grants.
        foreach ($db in @('kusakari','kusakari_e2e')) {
            $tables = (Invoke-MySql $adminUser $adminPassword $port "SELECT table_name FROM information_schema.tables WHERE table_schema='$db';").Output
            if ($tables) {
                $expected = @('products','stores','inventory','material_products','carts','cart_items','orders','order_items','flyway_schema_history')
                $actual = @($tables -split "`r?`n")
                if (@(Compare-Object $expected $actual).Count -gt 0) { throw "$db は既存の未知スキーマです。変更せず停止します。" }
                $history = (Invoke-MySql $adminUser $adminPassword $port "SELECT COUNT(*) FROM $db.flyway_schema_history WHERE version='1' AND script='V1__catalog_and_commerce.sql' AND success=1;").Output
                if ($history -ne '1') { throw "$db はKusakariの移行履歴と一致しません。変更せず停止します。" }
            }
        }
        $literal = $password.Replace("'", "''")
        $sql = "SET SESSION sql_mode='NO_BACKSLASH_ESCAPES'; CREATE USER IF NOT EXISTS '$user'@'localhost' IDENTIFIED BY '$literal';"
        foreach ($db in @('kusakari','kusakari_e2e')) {
            $sql += "CREATE DATABASE IF NOT EXISTS $db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,ALTER,DROP,INDEX,REFERENCES ON $db.* TO '$user'@'localhost';"
        }
        $null = Invoke-MySql $adminUser $adminPassword $port $sql
        $adminPassword = $null
        $null = Invoke-MySql $user $password $port 'USE kusakari; SELECT 1; USE kusakari_e2e; SELECT 1;'
        if (Test-Path -LiteralPath $settings) { Set-PrivateFile (Join-Path $runtimeDir 'env.previous') ([IO.File]::ReadAllText($settings)) }
        $lines = @("KUSAKARI_DATABASE_MODE=$mode", "KUSAKARI_DB_PORT=$port", "KUSAKARI_DB_USER=$user", "KUSAKARI_DB_PASSWORD='$password'", "KUSAKARI_DB_URL=jdbc:mysql://127.0.0.1:$port/kusakari?connectionTimeZone=UTC", "KUSAKARI_E2E_DB_URL=jdbc:mysql://127.0.0.1:$port/kusakari_e2e?connectionTimeZone=UTC")
        Set-PrivateFile $settings (($lines -join "`n") + "`n")
        Import-LocalSettings
    }
    $null = Invoke-MySql $user $password $port 'USE kusakari; SELECT 1; USE kusakari_e2e; SELECT 1;'
    $toolsFile = Join-Path $runtimeDir 'toolchain.json'
    $tools = Get-Content -Raw -LiteralPath $toolsFile | ConvertFrom-Json
    $tools | Add-Member -NotePropertyName MySql -NotePropertyValue $mysqlBin -Force
    $tools | ConvertTo-Json | Set-Content -LiteralPath $toolsFile -Encoding UTF8
    Write-Host '開発/E2E専用DBへのアプリユーザー認証を確認しました。'
}
