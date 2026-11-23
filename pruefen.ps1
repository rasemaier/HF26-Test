# Prueft lokal, ob du mit den Aufgaben fertig bist.
# Ausfuehren im Hauptordner deines Repos:   ./pruefen.ps1
# Falls Windows das Skript blockiert, einmalig:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
param(
    [string] $Tag   # optional, z.B. tag1 - sonst alle freigegebenen Tage
)

$ErrorActionPreference = 'Stop'
$basis = 'https://raw.githubusercontent.com/rasemaier/HF26/main/checks'
$ziel  = Join-Path ([System.IO.Path]::GetTempPath()) 'hf26-checks'
New-Item -ItemType Directory -Force -Path $ziel | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-CheckFile([string] $name) {
    $url = "$basis/$name"
    $file = Join-Path $ziel $name
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
    $file
}

try {
    Write-Host 'Lade aktuelle Checks von GitHub ...' -ForegroundColor DarkGray
    $released = Get-CheckFile 'released.json'
    Get-CheckFile 'lib.ps1' | Out-Null
    Get-CheckFile 'run.ps1' | Out-Null
    $json = Get-Content -LiteralPath $released -Raw | ConvertFrom-Json
    foreach ($t in @($json | ForEach-Object { $_ })) { Get-CheckFile "$t.ps1" | Out-Null }
}
catch {
    Write-Host "Checks konnten nicht geladen werden: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Bist du mit dem Internet verbunden?' -ForegroundColor Yellow
    exit 2
}

$runArgs = @{ RepoPath = $PSScriptRoot; ChecksRoot = $ziel; Lokal = $true }
if ($Tag) { $runArgs.Tag = $Tag }
& (Join-Path $ziel 'run.ps1') @runArgs
exit $LASTEXITCODE
