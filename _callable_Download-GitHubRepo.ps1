param (
    [Parameter(Mandatory=$true)]
    [string]$RepositoryUrl,

    [Parameter()]
    [string]$DestinationPath = $PWD.Path,

    [Parameter()]
    [string]$PreferredBranch = "master"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubRepoName {
    param([Parameter(Mandatory=$true)][string]$Url)

    $clean = $Url -replace '^https?://', ''
    $clean = $clean -replace '\.git$', ''

    $parts = $clean -split '/'
    if ($parts.Length -lt 3 -or $parts[0] -ne 'github.com') {
        throw "Unsupported GitHub URL: $Url"
    }

    return "$($parts[1])/$($parts[2])" # org/repo
}

function Test-RemoteBranchExists {
    param(
        [Parameter(Mandatory=$true)][string]$RepoUrl,
        [Parameter(Mandatory=$true)][string]$BranchName
    )

    # If branch exists, ls-remote outputs at least one line
    return @(git ls-remote --heads $RepoUrl $BranchName 2>$null).Count -gt 0
}

function Get-CloneBranch {
    param(
        [Parameter(Mandatory=$true)][string]$RepoUrl,
        [Parameter(Mandatory=$true)][string]$Preferred
    )

    if (Test-RemoteBranchExists -RepoUrl $RepoUrl -BranchName $Preferred) {
        return $Preferred
    }

    # Common fallback
    if (Test-RemoteBranchExists -RepoUrl $RepoUrl -BranchName "main") {
        return "main"
    }

    # Last resort: ask remote for HEAD branch (works in most cases)
    $headLine = git ls-remote --symref $RepoUrl HEAD 2>$null | Select-Object -First 1
    if ($headLine -match 'ref:\s+refs/heads/([^\s]+)\s+HEAD') {
        return $Matches[1]
    }

    throw "Could not determine a clone branch for $RepoUrl (no '$Preferred', no 'main', and HEAD not resolvable)."
}

$repoName = Get-GitHubRepoName -Url $RepositoryUrl
$org, $repo = $repoName -split '/', 2

$cloneBranch = Get-CloneBranch -RepoUrl $RepositoryUrl -Preferred $PreferredBranch

Write-Host "Remote branch '$cloneBranch' exists. Cloning $repoName ..." -ForegroundColor Yellow

# Clone into DestinationPath\<repo>
$targetDir = Join-Path $DestinationPath $repo

if (Test-Path $targetDir) {
    Write-Host "Skipping: target directory already exists: $targetDir" -ForegroundColor DarkYellow
    return
}

New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null

Push-Location $DestinationPath
try {
    git clone $RepositoryUrl --branch $cloneBranch --single-branch $repo
}
finally {
    Pop-Location
}
