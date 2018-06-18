# Script to collect logon activity to CSV. To be run weekly.
# Written by Greg Rowe (December 2016)

$Today     = Get-Date -Hour 0 -Minute 0 -Second 0
$PriorWeek = $Today.AddDays(-7)
$Yesterday = $Today.AddSeconds(-1)
$OU        = 'OU=ServerS,DC=domain,DC=TLD'
$Servers   = Invoke-Command -ComputerName FrontierDC3 { Param($OU) dsquery computer $OU -o rdn } -ArgumentList $OU | ForEach-Object { $_.replace('"','') }
$DateRange = "$( $PriorWeek.ToString('yyyy.MM.dd') )" + '-' + "$( $Yesterday.ToString('yyyy.MM.dd') )"
$Ext       = 'txt'
$FilePath  = "D:\Scripts\Get-LogonHistory_Output\RelinLoginHistory.$DateRange.$Ext"
$Results   = @()
$ID        = `
@{
    21 = 'Logon'
    23 = 'Logoff'
    24 = 'Disconnected'
    25 = 'Reconnection'
}
$Filter    = `
@{
    LogName   = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
    ID        = 21,23,24,25
    StartTime = $PriorWeek
    EndTime   = $Yesterday
}

ForEach( $Server in $Servers | Where-Object {$_} )
{
    Write-Output "Retrieving events from $Server..."
    [array]$Events += Get-WinEvent -ComputerName $Server -FilterHashtable $Filter
}

Write-Output 'Arranging events...'
ForEach($E in $Events)
{
    Write-Verbose "Working on Event: $($E.RecordID)"
    $EventMsg = ($E.Message -split '[\r\n]') | Where-Object {$_}
    $Result   = New-Object PSObject -Property `
    @{
        TimeCreated = $E.TimeCreated
        Server      = $E.MachineName.Split('.')[0]
        Activity    = $ID[$E.Id]
        User        = $EventMsg[1].Split('\')[1]
    }
    [array]$Results += $Result
}

$Results = $Results | Sort-Object -Property TimeCreated | Format-Table -AutoSize

Export-Csv -InputObject $Results -Path $FilePath -NoTypeInformation