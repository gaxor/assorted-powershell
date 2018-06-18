$EmailAddress = 'user1@domain.tld'
$Calendars = @(
    'calendar1'
    'calendar2'
)

$Permissions = New-Object PSCustomObject | Select ( $Calendars | Out-String -Stream )
$HashRequest = @{
    Uri = 'https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application#Microsoft.Online.CSE.PSModule.Client.application'
    Culture = 'neutral'
    PublicKeyToken = 'c3bce3770c238a49'
    processorArchitecture = 'msil'
    }


$WebRequest = 'https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application#Microsoft.Online.CSE.PSModule.Client.application, Culture=neutral, PublicKeyToken=c3bce3770c238a49, processorArchitecture=msil'
$OneClickApp = Invoke-WebRequest $WebRequest
[System.Diagnostics.Process]::Start( $OneClickApp.RawContent )

ForEach ( $Calendar in $Calendars )
{
    Write-Progress -Activity "Retrieving Calendar Permissions..." -CurrentOperation $Calendar -PercentComplete ( [Array]::IndexOf( $Calendars,$Calendar ) / $Calendars.Count * 100 )
    $Permissions.$Calendar = Get-MailboxFolderPermission -Identity ( $EmailAddress + ":\Calendar\" + $Calendar ) | Select User, AccessRights, Deny
}

# Get
Get-MailboxPermission TestMailbox@DOMAIN.TLD -user 'user2'

# Add
Add-MailboxPermission -Identity $EmailAddress -AccessRights FullAccess -User 'user2@DOMAIN.TLD' -AutoMapping:$False

# Set

# Remove
Remove-MailboxFolderPermission -Identity $EmailAddress -User 'user2@DOMAIN.TLD' -InheritanceType All
