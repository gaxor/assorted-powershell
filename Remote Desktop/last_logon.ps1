# Written by Greg Rowe (Aug 2015)
# Designed to find last logon date from a list (users.txt).
# Function "Get-ADUserLastLongon" found here: https://technet.microsoft.com/en-us/library/Dd378867(v=WS.10).aspx

function Get-ADUserLastLogon([string]$userName){
  $dcs = Get-ADDomainController -Filter {Name -like "DATACENTER1*"}
  $time = 0
  foreach($dc in $dcs)
  { 
    $hostname = $dc.HostName
    $user = Get-ADUser $userName | Get-ADObject -Properties lastLogonTimestamp 
    if($user.lastLogonTimestamp -gt $time) 
    {
      $time = $user.lastLogonTimestamp
    }
  }
  $dt = [DateTime]::FromFileTime($time)
  Write-Output "$username, $dt"  | Add-Content $outfile
}

write-verbose 'Loading AD Module...'
Try{
	Import-Module ActiveDirectory -ErrorAction Stop
}
Catch{
	write-host "[ERROR]`t ActiveDirectory Module couldn't be loaded."
	Exit 1
}

$file = Read-Host 'Enter user list path'
$outfile = Read-Host 'Enter export file path'

Get-Content $file | ForEach-Object {
    Get-ADUserLastLogon -username $_.
}
