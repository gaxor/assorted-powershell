# Check the Office 365 audit logs for non-US sign-in activity and email a report
# By Greg Rowe December 2018

<# Prerequisites:
	# Enable audit log search
	Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

	# Enable mailbox auditing
	Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -AuditEnabled $true

	# Service account needs the following permissions in Office 365
	New-RoleGroup -Name 'Audit Log Viewer' -Roles 'View-Only Audit Logs','MailboxSearch'
	Add-RoleGroupMember -Identity 'Audit Log Viewer' -Member $365AccountName
    Add-RoleGroupMember -Identity 'View-Only Organization Management' -Member $365AccountName
#>

[Array]$AllowedCountries = 'United States','Canada'
$LogDownloadInterval = 60 # in minutes
$365AccountName      = 'AuditLog@domain.com'
$365Password         = 'plaintextpassword'
$ToAddress           = 'reports@domain.com'
$FromAddress         = "noreply@domain.com"
$SMTPServer          = "personlizedsmtpserver.mail.protection.outlook.com"
$SMTPPort            = 25
$AccessKey           = '813ac381ce864351c338e48311c88135'

$HTMLStyle = '<style>
TABLE {
	border-width 1px;
	border-style: solid;
	border-color: black;
	border-collapse: collapse;
	font-family: calibri;}
TD {
	border-width: 1px;
	padding: 5px;
	border-style: solid;
	border-color: black;
	font-family: calibri}
TH {
	border-width: 1px;
	border-style: solid;
	border-color: black;
	padding: 5px;
	background-color: deepskyblue;
	font-family: calibri;}</style>'

# Connect to Office 365
Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOPSession = New-ExoPSSession -Credential ([PSCredential]::new($365AccountName,(ConvertTo-SecureString $365Password -AsPlainText -Force)))
Import-PSSession $EXOPSession

# Download latest user sign-in from the 365 audit log (in minutes)
$EndDate = [DateTime]::Now
$StartDate = [DateTime]::Now.AddMinutes(-$LogDownloadInterval)

$AuditResults = New-Object System.Collections.ArrayList
ForEach ($User in (Get-Mailbox -ResultSize Unlimited))
{
	$AuditParams = @{
		Identity = $User.Name
		#Mailboxes = 
		EndDate  = $EndDate
		StartDate = $StartDate
		Operations = 'MailboxLogin'
		ShowDetails = $True
	}

	$Result = Search-MailboxAuditLog @AuditParams | Select Operation, LogonUserDisplayName, MailboxOwnerUPN, ClientIPAddress, LastAccessed
	If ($Result.ClientIPAddress)
	{
		$Result | ForEach {[void]$AuditResults.Add($_)}
	}
}

# Check if logins are from non-US locations
ForEach ($Event in ($AuditResults | Sort -Unique -Property ClientIPAddress))
{
	$infoService = "http://api.ipstack.com/$($Event.ClientIPAddress)?access_key=$AccessKey"
	$geoip = Invoke-RestMethod -Method Get -URI $infoService | Select Country_Name, IP, City
	
	If ($geoip.Country_Name -notin $AllowedCountries)
	{
		# Send email report
		$Table = $AuditResults | Where {$_.ClientIPAddress -eq $Event.ClientIPAddress} | ConvertTo-Html -As Table -Head $HTMLStyle | Out-String
		$EmailInfo = @{
			Subject    = 'Non-US Email Sign-In Detected'
			Body       = $Table
			To         = $ToAddress
			From       = $FromAddress
			SmtpServer = $SMTPServer
			Port       = $SMTPPort
			BodyAsHtml = $True
		}
		Send-MailMessage @EmailInfo
	}
}

# Close 365 connection
Remove-PSSession $EXOPSession
