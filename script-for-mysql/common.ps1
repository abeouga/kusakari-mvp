$ErrorActionPreference = 'Stop'

function Find-KusakariProjectRoot {
    $directory = Get-Item -LiteralPath (Split-Path $PSScriptRoot -Parent)
    while ($directory) {
        $root = $directory.FullName
        if ((Test-Path -LiteralPath (Join-Path $root 'package.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $root 'backend') -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $root 'scripts\setup-existing-mysql.ps1') -PathType Leaf)) {
            return $root
        }
        $directory = $directory.Parent
    }
    throw 'Kusakariプロジェクトのルートを特定できません。script-for-mysqlをプロジェクト内に置いてください。'
}

$projectRoot = Find-KusakariProjectRoot
