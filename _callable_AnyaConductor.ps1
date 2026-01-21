<#
.SYNOPSIS
    Orchestrates repository listing, downloading, and building.
.DESCRIPTION
    This script first lists repositories from a GitHub organization (public), then downloads each one with default parameters,
    and finally builds the code combiner project.
#>
param (
    [string]$OrgName
)
# 1. List repositories for specified organization (no token for public repos)
$orgName = $OrgName
if (-not $orgName) {
    $orgName = Read-Host -Prompt "Enter GitHub organization name"
}
Write-Host "`nListing repositories for $orgName..." -ForegroundColor Cyan
& .\_callable_List-GitHubRepos.ps1 -OrgName $orgName

# Check if the output file was created successfully
if (-not (Test-Path -Path "RepositoryListOutput.txt")) {
    Write-Host "Error: Repository list file not found. Exiting." -ForegroundColor Red
    exit 1
}

# Set default download path to a 'Repos' subdirectory in current directory
$downloadPath = "$PWD/Repos"
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath | Out-Null
    Write-Host "Created download directory at: $downloadPath" -ForegroundColor Yellow
}

# 2. Download each repository from the list
Write-Host "`nDownloading repositories to $downloadPath..." -ForegroundColor Cyan

$repos = Get-Content -Path "RepositoryListOutput.txt"
foreach ($repo in $repos) {
    if ([string]::IsNullOrWhiteSpace($repo)) { continue }

    # Construct GitHub URL from org/repo format
    $repositoryUrl = "https://github.com/$orgName/$repo.git"

    Write-Host "Downloading repository: $repositoryUrl" -ForegroundColor Yellow

    & .\_callable_Download-GitHubRepo.ps1 `
        -RepositoryUrl $repositoryUrl `
        -DestinationPath $downloadPath `

    Start-Sleep -Seconds 31
}

cd ../

# 3. Build the code-combiner project
Write-Host "`nBuilding code-combiner..." -ForegroundColor Cyan

& .\_callable_Build-CodeCombiner.ps1
Write-Host "Build completed successfully!" -ForegroundColor Green
