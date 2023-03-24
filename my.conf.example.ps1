# Copy this example file to my.conf.ps1 and edit according to your requirements.

# Using an external DNS server overcomes problems of split DNS
$DNSServer = "8.8.8.8"

# Path to the file containing the DNS tests
$TestsFile = "$($PSScriptRoot)\dns-monitor.csv"

# Email settings - we use a hash table and splat it when passing to functions
$EmailConfig = @{
    From   = 'DNS Monitor - no reply <noreply@foo.com>'
    To     = @('recipient@one.com', 'recipient@two.com')
    Server = 'mail.foo.com'
    Port   = 587
    SSL    = $true
}
