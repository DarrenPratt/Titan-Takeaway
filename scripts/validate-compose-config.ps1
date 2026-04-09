[CmdletBinding()]
param(
    [string[]]$ComposeCandidates = @(
        "infra\docker\docker-compose.yml",
        "docker-compose.yml",
        "compose.yml"
    )
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$composeFile = $null
foreach ($candidate in $ComposeCandidates) {
    if (Test-Path $candidate) {
        $composeFile = $candidate
        break
    }
}

if (-not $composeFile) {
    Write-Host "❌ No compose file found. Checked: $($ComposeCandidates -join ', ')" -ForegroundColor Red
    exit 1
}

$dockerCli = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCli) {
    Write-Host "❌ Docker CLI not found in PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Using compose file: $composeFile"
& docker compose -f $composeFile config | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ docker compose config failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "✅ docker compose config parsed successfully." -ForegroundColor Green
