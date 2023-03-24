<#
.SYNOPSIS

Monitor DNS records and alert on any changes.

.DESCRIPTION

This script tests DNS entries in a CSV file against known good settings and
sends an email to alert on any discrepancy. The script currently handles
records of type A, MX, NS and TXT.

The first line in the CSV file should be headings. E.g.:
    DNS,Type,Find,Count,Match,Notes

Required CSV fields:
    - DNS: The DNS entry to search for (e.g. pomeroy.me) Type: Type of DNS
        record to query (A, MX, NS or TXT)
    - Find: perform an exact match; leave blank if comparing record count
    - Count: If Find isn't set, test the total number of records of this
        type returned. Otherwise check the number matching the search.
        If we leave Count blank, make sure there's at least one such record.
    - Match:
        - A, MX or NS records: Not used
        - MX records: The preference level this record should be set to
            (e.g. "10"; leave blank if we don't care). Only use if searching
            for a particular MX record.

CSV example lines:
    "pomeroy.me","A","","8","":
        Ensure there are exactly 8 A (RRDNS) records for pomeroy.me

    "pomeroy.me","A","104.21.4.209","1","":
        Make sure there's exactly one A record for pomeroy.me, exactly matching
        104.21.4.209

    "pomeroy.me","MX","aspmx.l.google.com","1","10":
        Make sure there's exactly one MX record for pomeroy.me exactly matching
        aspmx.l.google.com and which has priority 10

    "pomeroy.me","TXT","v=spf1 foobar","1","":
        Make sure there's exactly one TXT record exactly matching
        "v=spf1 foobar"

.EXAMPLE

PS> .\Start-DNSMonitor.ps1

.LINK

https://github.com/robpomeroy/dns-monitor

.NOTES

Author: Rob Pomeroy
Licence: GPL3
Version: v0.1.0-alpha [Set also in the $Version variable]
Date:    23 March 2023

Version history:

    v0.1.0 - 24 March 2023 - alpha release

TODO:
- Monitor AAAA records
- Monitor CNAME records
- Monitor PTR records
- Monitor SOA records
- Monitor SRV records
- Monitor SPF records
- Test against multiple DNS servers
- Cater for geographically-specific DNS results
#>


################
## INITIALISE ##
################

Set-StrictMode -Version 3.0
$Version = 'v0.1.0-alpha'

# Load functions
. "$PSScriptRoot\functions\Send-Email.ps1"

# Load username and password from credentials files
try {
    # Credentials are stored under user profile
    $SMTPcreds = Import-CliXml -Path "$env:LOCALAPPDATA\creds\DNSMonitor-SMTP.xml"
}
catch {
    Throw "Error: [$Version] unable to load credentials. Please run Set-Creds.ps1 first."
}

# Load configuration file
try {
    . "$PSScriptRoot\my.conf.ps1"
}
catch {
    Throw "Error: [$Version] unable to load configuration file 'my.conf.ps1'. Check my.conf.example.ps1."
}

<#
Set error handling (can't do this earlier since we need SMTP credentials and
SMTP settings).
#>
trap {
    $e = $_
    $Message = ("<h1>DNS MONITOR SCRIPT ERROR [$Version]</h1><p>" +
        $e.Exception.Message + "</p><p>" +
        "Problem calling $($e.InvocationInfo.MyCommand)" +
        $(
            if($e.Exception.PSobject.Properties.Name -match "ItemName") {
                " with $($e.Exception.ItemName)"
            }
        ) + "</p>" +
        $e.InvocationInfo.PositionMessage
    )
    Send-Email @EmailConfig -Subject "DNS Monitor script error [$Version]" -Body $Message -Credential $SMTPcreds
    break
}
$ErrorActionPreference = "Stop"

<#
Initialize errors list, which will contain any error messages. Lists are
easier to append to than arrays in PowerShell.
#>
$DNSErrors = New-Object System.Collections.Generic.List[System.Object]

<#
Different types of DNS records have different property names in their results,
so we need to name filters accordingly.

Ditto for the field against which we perform any match

This is a hashtable (like a dictionary in other languages)
#>
$FilterNames = @{
    A   = "IPAddress"
    MX  = "NameExchange"
    TXT = "Strings"
    NS  = "NameHost"
}
$MatchNames = @{
    MX  = "Preference"
}

# Make sure the tests file exists
If (Test-Path $TestsFile) {
    $Tests = Import-csv $TestsFile
}
Else {
    Throw ("Error: {0} doesn't exist; aborting" -f $TestsFile)
    Exit 2
}

# Iterate over the tests from the CSV file
ForEach ($Test in $Tests) {

    # Load DNS records, filtering by the "Find" column from the CSV file if it's not empty
    If ([string]::IsNullOrEmpty($Test.("Find"))) {

        # Nothing to find, so just resolve the DNS entry
        $Records = Resolve-DnsName -Name $Test.("DNS") -Type $Test.("Type") -Server $DNSServer -DnsOnly

    }
    Else {

        # Resolve the DNS entry and filter based on the 'Find' column
        $Records = Resolve-DnsName -Name $Test.("DNS") -Type $Test.("Type") -Server $DNSServer -DnsOnly |
            Where-Object -Property $FilterNames[$Test.("Type")] -eq $Test.("Find")

    }
    
    If (($Records | Measure-Object).Count -eq 0 -and $Test.("Count") -ne 0) {

        $strValues = @(
            $Test.("Type")
            $Test.("DNS")
        )

        # We didn't get any matching records for this test, but we should have
        $DNSErrors.Add("Couldn't get the {0} record(s) for {1}." -f $strValues )
        
    }
    Else {
        
        # Test quantity, if the "Count" column is set - there should be exactly this many records
        If (-Not [string]::IsNullOrEmpty($Test.("Count"))) {
            If (@($Records).Count -ne $Test.("Count")) {
                $strValues = @(
                    $Test.("DNS")
                    $Test.("Type")
                    $Test.("Find")
                    $Test.("Count")
                    $Records.Count
                )
                $DNSErrors.Add("DNS record count {0} | {1} | {2} should be exactly {3}. Instead it's {4}." -f $strValues)
            }
        }


        # If "Match" is set, we test the first object in the array for an exact match.
        If (-Not [string]::IsNullOrEmpty($Test.("Match")) -and $Records[0].($MatchNames[$Test.('Type')]) -ne $Test.("Match")) {
            $strValues = @(
                $Test.("DNS")
                $Test.("Type")
                $Test.("Find")
                $Records[0].($MatchNames[$Test.('Type')])
                $Test.("Match")
            )
            $DNSErrors.Add("DNS record {0} | {1} | {2} contains:<br />`r`n&nbsp;&nbsp;&nbsp;{3}<br />`r`nwhich does not match required text:<br />`r`n&nbsp;&nbsp;&nbsp;{4}" -f $strValues)
        }

    }

}


# Styles and HTML structures for email report
$CellStyle = 'style="border: 1px solid black; padding: 5px;"'
$TablePre = @"
<table style="border: 1px solid black; border-collapse: collapse;">
  <tbody>
    <tr>
      <td $($CellStyle)>
"@
$TablePost = @"
      </td>
    </tr>
  </tbody>
</table>
"@


# If there are any errors, send an email
If ($DNSErrors.Count -gt 0) {

    # Convert $DNSErrors list to a string, to use as body of email
    $DNSErrorsHTML = $DNSErrors -join "</td></tr>`r`n<tr><td $($CellStyle)>" | Out-String
    $Body = "<p>[$Version] DNS record exceptions report:</p>$($TablePre)$($DNSErrorsHTML)$($TablePost)"

    try {

        # Send email
        Send-Email @EmailConfig -Body $Body -Credential $SMTPcreds `
            -Subject "Scheduled DNS monitoring script running on $($Env:ComputerName) [$Version]" `
            -ErrorAction Stop
    }
    catch {

        Throw ("Error: [$Version] could not send email; aborting")
        Exit 2

    }
}