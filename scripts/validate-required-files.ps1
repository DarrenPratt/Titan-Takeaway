[CmdletBinding()]
param(
    [string[]]$RequiredPaths = @(
        "Titan-Takeaway.Services.slnx",
        "README.md",
        "services\ordering-api\ordering-api.csproj",
        "services\payment-service\payment-service.csproj",
        "services\kitchen-service\kitchen-service.csproj",
        "services\delivery-service\delivery-service.csproj",
        "infra\otel-collector\otel-collector-config.yaml",
        "infra\prometheus\prometheus.yml"
    ),
    [string[]]$ComposeCandidates = @(
        "infra\docker\docker-compose.yml",
        "docker-compose.yml",
        "compose.yml"
    )
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$missing = @()

foreach ($path in $RequiredPaths) {
    if (-not (Test-Path $path)) {
        $missing += $path
    }
}

$composeFound = $false
foreach ($composePath in $ComposeCandidates) {
    if (Test-Path $composePath) {
        $composeFound = $true
        break
    }
}

if (-not $composeFound) {
    $missing += "docker compose file (expected one of: $($ComposeCandidates -join ', '))"
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Required files missing:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "✅ Required start/build files are present." -ForegroundColor Green
