# DNS Monitor

This is a PowerShell script, intended for scheduled use, to query DNS records
and send an email if they deviate from predefined values. No email is sent if
eveything matches.

The main script (`Start-DNSMonitor.ps1`) also sends an email if errors are
encountered.

## Usage

1. Create a CSV containing your required tests.
2. Edit your configuration file.
3. Set SMTP credentials.
4. Optional: schedule the script to run, e.g. daily.

For the first three points, read further, below.

## Tests file

The script uses the `dns-monitor.csv` file to define the records to monitor.
`dns-monitor.xlsx` is a template for this file. Make changes to the Excel
spreadsheet and then export as the CSV file for use by the script.

## Configuration

Copy `my.conf.example.ps1` to `my.conf.ps1` and edit to suit your needs. This is
a PowerShell script, dot-sourced by the main script.

## SMTP Credentials

The script sends the report by authenticated SMTP. Set the values for your
SMTP server in `my.conf.ps1`. Run the `Set-Creds.ps1` script to store the SMTP
credentials securely.

Credentials are stored at `$env:LOCALAPPDATA\creds\DNSMonitor-SMTP.xml`, using
the Data Protection API (DPAPI). The DPAPI keys the content's the user of the
script. You must therefore run `Set-Creds.ps1` as the user that will run the
script (e.g. as a scheduled task).

Read more about
[DPAPI here](https://learn.microsoft.com/en-us/dotnet/standard/security/how-to-use-data-protection).

## Disclaimer

This is alpha-quality. It works for me, but has not been tested exhaustively.
It shouldn't break your computer, but I've no idea what will happen if you try
to test a gajillion DNS records at once.

Also, I may never do anything on the TODO list. Pull requests are welcome.

## Rationale

DNS records are the crown jewels for many internet-facing services. How do you
know if your DNS registrar has been compromised and records maliciously changed?