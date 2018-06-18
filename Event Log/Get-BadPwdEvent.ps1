$username = 'username'
$Servers = @()

ForEach($server in $Servers){
        invoke-command -computername $server -ArgumentList $server,$username {
             Get-WinEvent -FilterHashtable @{StartTime=(get-date).AddDays(-1);Logname='Security';Id=4625} | where{$_.message -like "*$username*"}
        } -AsJob
}

get-job | Wait-Job
$badpwdids = get-job | Receive-Job -Keep

remove-job * -force

$badpwdids | select MachineName | Sort-Object -Unique -Property MachineName