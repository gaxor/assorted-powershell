$Events = Get-WinEvent -FilterHashtable @{StartTime=(get-date).AddDays(-1);Logname='Security';Id=4625}
$Output = @()
ForEach( $Event in $Events )
{
    $Message = ( $Event.Message -split 'Account For Which Logon Failed:' )[1]
    $Output += $Message | Select `
    @{
        Name       = 'TimeCreated'
        Expression = { $Event.TimeCreated }
    }, `
    @{
        Name       = 'AccountName'
        Expression = { ( ( [regex]::Match($Message,'[\n\r].*Account Name:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
    }, `
    @{
        Name       = 'FailureReason'
        Expression = { ( ( [regex]::Match($Message,'[\n\r].*Failure Reason:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
    }
}

Write-Output $Output