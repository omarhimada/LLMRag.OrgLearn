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

Start-Transcript -Path ".\run.log" -Force
try {
    .\_callable_AnyaConductor.ps1 -OrgName $orgName
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor OrangeRed
}
finally {
    Stop-Transcript
}

Write-Host ""
Write-Host "Script finished. Log saved to run.log"
Write-Host "Press Enter to close..."

[void] (Read-Host)