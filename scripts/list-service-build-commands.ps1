[CmdletBinding()]
param(
    [string]$ServicesRoot = "services"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

if (-not (Test-Path $ServicesRoot)) {
    Write-Host "❌ Services root not found: $ServicesRoot" -ForegroundColor Red
    exit 1
}

$projects = Get-ChildItem -Path $ServicesRoot -Recurse -Filter *.csproj | Sort-Object FullName

if (-not $projects) {
    Write-Host "❌ No service .csproj files found under $ServicesRoot." -ForegroundColor Red
    exit 1
}

Write-Host "Service build commands:"
foreach ($project in $projects) {
    $relative = Resolve-Path -Relative $project.FullName
    Write-Host " - dotnet build $relative"
}
