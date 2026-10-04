$ErrorActionPreference = 'Stop'

function Get-KusakariMySqlBin {
  param([switch]$Portable)
  $installed = Get-Command mysqld.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  $candidates = @()
  $stateRoot = if ($env:KUSAKARI_MYSQL_HOME) { $env:KUSAKARI_MYSQL_HOME } else { Join-Path $env:LOCALAPPDATA 'Kusakari\mysql' }
  $stateFile = Join-Path $stateRoot 'instance.json'
  if (Test-Path -LiteralPath $stateFile) {
    $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    $candidates += Split-Path -Parent $state.executable
  }
  if (-not $Portable) {
    if ($null -ne $installed) { $candidates += Split-Path -Parent $installed.Source }
    foreach ($version in @('8.4', '8.0')) {
      $candidates += Join-Path $env:ProgramFiles "MySQL\MySQL Server $version\bin"
    }
  }
  $version = '8.4.11'
  $tools = Join-Path $env:LOCALAPPDATA "Kusakari\tools\mysql-$version-winx64"
  $candidates += Join-Path $tools 'bin'
  foreach ($candidate in $candidates) {
    if ((Test-Path -LiteralPath (Join-Path $candidate 'mysqld.exe')) -and
        (Test-Path -LiteralPath (Join-Path $candidate 'mysqldump.exe'))) {
      return $candidate
    }
  }

  $architecture = $env:PROCESSOR_ARCHITEW6432
  if (-not $architecture) { $architecture = $env:PROCESSOR_ARCHITECTURE }
  if ($architecture -ne 'AMD64') { throw 'MySQL自動導入はWindows x64に対応しています。' }
  $downloads = Join-Path $env:LOCALAPPDATA 'Kusakari\downloads'
  New-Item -ItemType Directory -Path $downloads -Force | Out-Null
  $archive = Join-Path $downloads "mysql-$version-winx64.zip"
  $expected = 'A492371D687D2BAB088B0062581144A0044B8964BAEFDF4FAA579292B423D25C'
  if (-not (Test-Path -LiteralPath $archive)) {
    Write-Host "Kusakari専用MySQL ${version}を公式配布元から取得します。"
    $partial = "$archive.part"
    $uri = "https://cdn.mysql.com/Downloads/MySQL-8.4/mysql-$version-winx64.zip"
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
      & curl.exe --fail --location --retry 2 --connect-timeout 30 --output $partial $uri
      if ($LASTEXITCODE -ne 0) { throw 'MySQL配布物を取得できませんでした。ネット接続を確認して再実行してください。' }
    } else {
      Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $partial -TimeoutSec 900
    }
    Move-Item -LiteralPath $partial -Destination $archive -Force
  }
  if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) {
    throw "MySQL配布物のSHA-256が一致しません。取得ファイルを確認してください: $archive"
  }

  $stage = Join-Path $downloads ('mysql-extract-' + [guid]::NewGuid().ToString('N'))
  try {
    Write-Host 'MySQLをユーザー領域へ展開します。'
    Expand-Archive -LiteralPath $archive -DestinationPath $stage
    $source = Join-Path $stage "mysql-$version-winx64"
    foreach ($name in @('mysqld.exe', 'mysqldump.exe', 'mysql.exe')) {
      $signature = Get-AuthenticodeSignature -LiteralPath (Join-Path $source "bin\$name")
      if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O="?Oracle America') {
        throw "MySQL配布物のOracle署名を確認できません: $name"
      }
    }
    if (Test-Path -LiteralPath $tools) { throw "MySQLの展開先が既に存在します。既存ファイルを確認してください: $tools" }
    Move-Item -LiteralPath $source -Destination $tools
  } finally {
    $resolvedStage = [IO.Path]::GetFullPath($stage)
    if ($resolvedStage.StartsWith([IO.Path]::GetFullPath($downloads) + '\', [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedStage)) {
      Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
  }
  return (Join-Path $tools 'bin')
}

function Initialize-KusakariMySqlRuntime {
  param([string]$Bin)
  $key = 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
  $runtime = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
  if ($runtime.Installed -ne 1 -or $runtime.Major -lt 14 -or ($runtime.Major -eq 14 -and $runtime.Minor -lt 29)) {
    Write-Host 'MySQLに必要なMicrosoft Visual C++ランタイムを導入します。Windowsの管理者確認が表示される場合があります。'
    $installer = Join-Path $env:LOCALAPPDATA 'Kusakari\downloads\vc_redist.x64.exe'
    New-Item -ItemType Directory -Path (Split-Path -Parent $installer) -Force | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $installer -TimeoutSec 300
    $signature = Get-AuthenticodeSignature -LiteralPath $installer
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
      throw 'Visual C++ランタイムのMicrosoft署名を確認できません。'
    }
    $process = Start-Process -FilePath $installer -ArgumentList @('/install', '/quiet', '/norestart') -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -notin @(0, 1638, 3010)) { throw "Visual C++ランタイムの導入に失敗しました (exit $($process.ExitCode))。" }
  }
  & (Join-Path $Bin 'mysqld.exe') --no-defaults --version
  if ($LASTEXITCODE -ne 0) { throw 'MySQL実行ファイルを起動できません。Visual C++ランタイムとWindows x64環境を確認してください。' }
}
