<#
.SYNOPSIS
    Downloads a GitHub repository to the specified directory.
.DESCRIPTION
    This script clones a GitHub repository using git if available,
    otherwise downloads a ZIP archive of the specified branch (defaults to main).
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$RepositoryUrl,
    [string]$DestinationPath = $PWD.Path,
    [string]$MainBranch = "main",
    [string]$MasterBranch = "master"
)

function Get-GitHubRepoName {
    param([string]$Url)
    if ($Url -like '*github.com/*') {
        # Remove https:// and split by '/'
        $urlNoHttps = $Url -replace '^https?://', ''
        $parts = $urlNoHttps -split '/'
        return "$($parts[0])/$($parts[1] -replace '\.git$', '')"
    } else {
        throw "Unsupported GitHub URL: $Url"
    }
}

# Check if they're using 'main' or 'master' branch
$branchExists = git branch --list | Where-Object { $_.Trim() -eq $MainBranch } | Measure-Object | Select-Object -ExpandProperty Count

if ($branchExists -gt 0) {
    Write-Host "Local branch '$MainBranch' exists."
    Write-Host "Cloning repository with git..."
    cd $DestinationPath
    git clone $RepositoryUrl --branch $MainBranch
    cd ../
    return
} else {
    Write-Host "Local branch '$MainBranch' does not exist."
    Write-Host "Trying branch '$MasterBranch'."
    Write-Host "Cloning repository with git..."
    cd $DestinationPath
    git clone $RepositoryUrl --branch $MainBranch
    cd ../
    return
}