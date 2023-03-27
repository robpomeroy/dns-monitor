<#
.SYNOPSIS
Set up SMTP credentials for DNS Monitor script

.EXAMPLE
If PowerShell script execution is permitted, from a PowerShell prompt:

    .\Set-Creds.ps1

.NOTES
Author: Rob Pomeroy
Licence: GPL3
Version: v0.2.0-alpha
Date:    27 March 2023

Version history:

    v0.2.0 - 27 March 2023 - improvements following ScriptAnalyzer review
    v0.1.0 - 24 March 2023 - alpha release

#>

$Version = 'v0.0.2-alpha'

Write-Output (-join @(
    "This script [$Version] prompts for credentials, for use by the DNS "
    "Monitor script. It only needs to be run once for the user account under "
    "which this script will run."
))

# Store credentials under user profile
$credsDir = $env:LOCALAPPDATA + "\creds"

# Check for the creds directory; create it if it doesn't exist
If(-not (Test-Path -Path $credsDir -PathType Container)) {
    New-Item -Path $credsDir -ItemType Directory | Out-Null
}

# Request credentials and store in secure file
$Credential = Get-Credential -Message "Enter SMTP username and password"
if($null -eq $Credential) {
    Write-Output "No credentials entered; cancelling."
} else {
    $Credential | Export-CliXml -Path "$credsDir\DNSMonitor-SMTP.xml"
}

Write-Output "Set-Creds.ps1 [$Version] completed."