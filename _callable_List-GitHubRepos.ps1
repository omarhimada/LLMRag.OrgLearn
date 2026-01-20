<#
.SYNOPSIS
    Lists all repositories in a given GitHub organization and saves them to RepositoryListOutput.txt, excluding specific repositories like .github.
.DESCRIPTION
    This script uses the GitHub API to fetch repository names for an organization and writes them to a file after filtering out excluded repositories.
    For private repositories, you'll need to provide a personal access token.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$OrgName,

    [string]$Token = $null  # Optional: GitHub personal access token
)

$headers = @{}
if ($Token) {
    $headers["Authorization"] = "token $Token"
}

# List of repositories to exclude (e.g., .github)
$excludedRepos = @(".github")

try {
    $url = "https://api.github.com/orgs/$OrgName/repos?per_page=100"

    Write-Host "Fetching repositories for organization: $OrgName" -ForegroundColor Cyan

    # Initialize array to store repository names
    $repoNames = @()

    # Get the first page of results
    $response = Invoke-RestMethod -Uri $url -Headers $headers

    if ($null -eq $response) {
        Write-Host "No repositories found or organization does not exist." -ForegroundColor Yellow
        return
    }

    # Collect repository names from first page, excluding certain repos
    foreach ($repo in @($response)) {
        if (-not ($excludedRepos -contains $repo.name)) {
            $repoNames += $repo.name
        }
    }

    # Display count (optional, but keeps some console output)
    Write-Host "Found $(@($response).Count) repositories" -ForegroundColor Green

    # Handle pagination if there are more pages
    $page = 2
    while ($true) {
        $nextUrl = $url + "&page=$page"
        try {
            $moreRepos = Invoke-RestMethod -Uri $nextUrl -Headers $headers

            # Check if response is not null and contains items
            if ($moreRepos -and $moreRepos.Count -gt 0) {
                foreach ($repo in @($moreRepos)) {
                    if (-not ($excludedRepos -contains $repo.name)) {
                        $repoNames += $repo.name
                    }
                }
                $page++
            } else {
                # No more repositories available, break out of the loop
                break
            }
        } catch [System.Net.WebException] {
            # Handle other potential errors (not just 404)
            throw
        }
    }

    # Write all repository names to file after filtering
    $repoNames | Out-File -FilePath "RepositoryListOutput.txt" -Encoding utf8

    Write-Host "Repository list has been saved to RepositoryListOutput.txt with a total of $($repoNames.Count) entries (after excluding specified repos)." -ForegroundColor Green

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
