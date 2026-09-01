#Requires -Version 5.1
<#
.SYNOPSIS
  ローカルのグローバル指示ファイル (~/.claude/CLAUDE.md) と、このリポジトリを同期する。

.DESCRIPTION
  -Push  : このPCの原本 → リポジトリ → GitHub へ反映
  -Pull  : GitHub の最新 → このPCの原本（上書き前に控えを取る）
  -Check : 一致しているかだけ表示（何も書き換えない）

  認証は GitHub CLI (gh) のログイン情報を使う。事前に gh auth login が必要。
#>
[CmdletBinding()]
param(
    [switch]$Push,
    [switch]$Pull,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$RepoDir  = $PSScriptRoot
$RepoFile = Join-Path $RepoDir 'CLAUDE.md'
$SrcFile  = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
$RemoteNoAuth = 'https://github.com/kageug/claude-global-instructions.git'

function Get-GitExe {
    $c = Get-Command git -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $fallback = 'E:\20.apli\Git\Git\cmd\git.exe'
    if (Test-Path $fallback) { return $fallback }
    throw 'git が見つかりません。'
}

function Get-GhExe {
    $c = Get-Command gh -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $fallback = Join-Path $env:LOCALAPPDATA 'GitHubCLI\bin\gh.exe'
    if (Test-Path $fallback) { return $fallback }
    throw 'GitHub CLI (gh) が見つかりません。'
}

function Get-Sha256([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
}

$git = Get-GitExe

if (-not $Push -and -not $Pull -and -not $Check) {
    Write-Host '使い方: sync.ps1 -Push | -Pull | -Check'
    exit 1
}

if (-not (Test-Path $SrcFile)) {
    throw "原本が見つかりません: $SrcFile"
}

# ---------------------------------------------------------------- Check
if ($Check) {
    $a = Get-Sha256 $SrcFile
    $b = Get-Sha256 $RepoFile
    Write-Host "原本      : $SrcFile"
    Write-Host "リポジトリ: $RepoFile"
    if ($a -eq $b) {
        Write-Host '一致しています。'
    } else {
        Write-Host '一致していません。'
        Write-Host '--- 差分（左=リポジトリ / 右=原本） ---'
        & $git --no-pager diff --no-index -- $RepoFile $SrcFile
    }
    exit 0
}

# ---------------------------------------------------------------- Pull
if ($Pull) {
    & $git -C $RepoDir fetch origin
    if ($LASTEXITCODE -ne 0) { throw 'fetch に失敗しました。' }
    & $git -C $RepoDir merge --ff-only origin/main
    if ($LASTEXITCODE -ne 0) { throw 'ローカルが分岐しています。手動で解決してください。' }

    if ((Get-Sha256 $SrcFile) -eq (Get-Sha256 $RepoFile)) {
        Write-Host '原本は既に最新です。何もしませんでした。'
        exit 0
    }

    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$SrcFile.bak-$stamp"
    Copy-Item -LiteralPath $SrcFile -Destination $backup -Force
    Copy-Item -LiteralPath $RepoFile -Destination $SrcFile -Force
    Write-Host "控えを作成: $backup"
    Write-Host "原本を更新: $SrcFile"
    exit 0
}

# ---------------------------------------------------------------- Push
if ($Push) {
    Copy-Item -LiteralPath $SrcFile -Destination $RepoFile -Force

    & $git -C $RepoDir add -- 'CLAUDE.md'
    & $git -C $RepoDir diff --cached --quiet -- 'CLAUDE.md'
    if ($LASTEXITCODE -eq 0) {
        Write-Host '差分はありません。何もしませんでした。'
        exit 0
    }

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
    & $git -C $RepoDir commit -m "update CLAUDE.md ($stamp)" -- 'CLAUDE.md'
    if ($LASTEXITCODE -ne 0) { throw 'コミットに失敗しました。' }

    # push 直前に最新化してから載せ直す
    & $git -C $RepoDir fetch origin
    if ($LASTEXITCODE -ne 0) { throw 'fetch に失敗しました。' }
    & $git -C $RepoDir rebase origin/main
    if ($LASTEXITCODE -ne 0) { throw 'origin/main への載せ直しに失敗しました。手動で解決してください。' }

    $gh = Get-GhExe
    $token = (& $gh auth token).Trim()
    if (-not $token) { throw 'gh のトークンを取得できません。gh auth login を実行してください。' }
    $authUrl = $RemoteNoAuth -replace '^https://', "https://kageug:$token@"

    & $git -C $RepoDir push $authUrl 'HEAD:main'
    if ($LASTEXITCODE -ne 0) { throw 'push に失敗しました。' }

    Write-Host 'GitHub へ反映しました。'
    Write-Host 'https://github.com/kageug/claude-global-instructions/blob/main/CLAUDE.md'
    exit 0
}
