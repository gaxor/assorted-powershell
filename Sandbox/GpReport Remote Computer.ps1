$path     = "C:\gpreport.html"
$computer = 'computername'
$cred     = Get-Credential
$sblock   = {Get-GPResultantSetOfPolicy -Computer $using:computer -User $using:cred.UserName -ReportType html -Path $using:path}

Invoke-Command -ScriptBlock $sblock -Credential $cred -ComputerName localhost
