# Designed to query all servers on the domain for a given user
# Written by Greg Rowe (June 2016)

Param
(
    [Parameter(Mandatory=$True)]
    [string]$Username
)

$Computers = ( Get-ADComputer -Filter * | Format-Table -HideTableHeaders -Property 'Name' | Out-String -Stream | Sort-Object ).Trim() | where { $_ -ne '' }
ForEach($C in $Computers)
{
    $LoggedIn = ( ( quser /server:$C | ? { $_ -match $Username } ) -split ' +' )
    If ( { $_ -ne '' } )
    {
        #Write-Host '-----------------------'
        Write-Host "Server : $C"
        Write-Host ( 'Session:' ),( $LoggedIn[2] )
        #Clear-Variable loggedin
        $LoggedIn = ''
    }
}