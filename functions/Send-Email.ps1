function Send-Email {
    <#
    .SYNOPSIS
    Send specified message to the recipients.
    
    .DESCRIPTION
    Accepts message (string) and sends it to the recipients specified, using
    authenticated SMTP.
    
    .PARAMETER From
    The email sender.
    
    .PARAMETER To
    An array of recipient email addresses.
                
    .PARAMETER Subject
    The subject for the email.
                
    .PARAMETER Server
    The SMTP server to use.
                
    .PARAMETER Port
    The SMTP port to use.
                
    .PARAMETER Body
    The message string
    
    .PARAMETER Credential
    Credentials to authenticate with SMTP server.
                
    .EXAMPLE
    Send-Email `
        -To @("first@person.com", "someone@else.com") `
        -From "DNS Monitor - do not reply <donotreply@mydomain.com>" `
        -Subject "DNS Monitor Report" `
        -Body "Test email"
        -Server "my.server.com" `
        -Port 587 `
        - SSL $true `
        -Credential $Credential
    
    But it will probably be more convenient to use a splatted hash, e.g.:

        Send-Email @EmailConfig -Subject "Test email"
    #>
    
        Param(
            [Parameter(Mandatory = $true)][string]$From,
            [Parameter(Mandatory = $true)][Array]$To,
            [Parameter(Mandatory = $true)][string]$Subject,
            [Parameter(Mandatory = $true)][string]$Body,
            [Parameter(Mandatory = $true)][string]$Server,
            [Parameter(Mandatory = $true)][int]$Port,
            [Parameter(Mandatory = $true)][bool]$SSL,
            [Parameter(Mandatory = $true)][PSCredential]$Credential
        )
    
        # Create the message object (using a .NET component with SMTP auth capability)
        $Message = New-Object Net.Mail.MailMessage
        $Message.From = $From
        # foreach ($Recipient in $To) {
        #     $Message.To.Add($Recipient)
        # }
        $Message.To.Add($To) # Testing this
        $Message.Subject = $Subject
        $Message.IsBodyHtml = $true
        $Message.Body = "$Body"
    
        # Set up and send the email
        $smtp = New-Object Net.Mail.SmtpClient($Server, $Port)
        $smtp.EnableSSL = $SSL
        $smtp.Credentials = $Credential
        $smtp.Send($Message)
        
        $smtp.Dispose()
        $Message.Dispose()
    }