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

    [string]$Branch = "main"
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


Write-Host "Cloning repository with git..."
cd $DestinationPath
git clone $RepositoryUrl --branch $Branch
cd ../
return

