# Script to collect failed logon activity and save to CSV files. To be run Daily.
# Written by Greg Rowe (March 2017)

$Servers = 'server1','server2'
#$OU      = 'OU=Servers,dc=Domain,dc=tld'
#$Servers = Invoke-Command -ComputerName 'DOMAIN_CONTROLLER' { Param($OU) dsquery computer $OU -o rdn } -ArgumentList $OU | ForEach-Object { $_.replace('"','') }
$Day     = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-1)
$Path    = 'D:\Scripts\Get-FailedLogonHistory_Output'
$File    = "$( $Day.ToString('yyyy.MM.dd') ).FailedLogons.csv"
$Filter  = @{
    logname   = 'Security'
    ID        = 4776
    StartTime = $Day
    EndTime   = ($Day).AddDays(1) }

ForEach($Server in $Servers)
{
    Write-Output "Retrieving events from $Server..."
    [array]$Events += Get-WinEvent -ComputerName $Server -FilterHashtable $Filter
}

Write-Output 'Arranging events...'
ForEach($E in $Events)
{
    $EventMsg = $E.Message.Split("`r`n") | Where { $_ }
    $Result   = New-Object PSCustomObject -Property `
    @{
        Server  = $E.MachineName
        Account = $EventMsg[2].Substring(15)
        Source  = $EventMsg[3].Substring(20)
        Time    = $E.TimeCreated
    }
    [array]$Results += $Result
}

$Results | Export-Csv -Path (Join-Path $Path $File) -NoTypeInformation

# The next line is commented out because Export-Csv has issues with hashtables
# Export-Csv -InputObject $Results -Path $FilePath -NoTypeInformation

<# Save to txt file:
$Results = $Results | Sort-Object -Property TimeCreated | Format-Table -AutoSize
Out-File -InputObject $Results -FilePath $FilePath -NoClobber -Append
#>