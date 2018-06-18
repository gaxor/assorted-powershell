# Connect to 365 as remote session
Import-Module Microsoft.PowerShell.Utility
Import-Module MSOnline -force
Import-Module MSOnlineExtended -force
Import-Module Microsoft.Online.SharePoint.PowerShell -force
$credential = Get-Credential
Connect-MsolService -Credential $credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $credential -Authentication Basic -AllowRedirection
Import-PSSession $Session

# Add distribution list for each domain for each user (and set permissions)
$Mailboxes = Get-Mailbox
Foreach ($m in $Mailboxes){
    $a1 = $m.alias + "@domain.tld"
    New-DistributionGroup -Name $a1 -DisplayName $a1 -PrimarySmtpAddress $a1
    Set-DistributionGroup -Identity $a1 -RequireSenderAuthenticationEnabled $False
    Add-DistributionGroupMember -Identity $a1 -Member $m.name -BypassSecurityGroupManagerCheck
    Add-RecipientPermission $a1 -Trustee $m.Name -AccessRights SendAs -Confirm:$False
}

