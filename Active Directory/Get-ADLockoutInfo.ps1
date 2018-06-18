# Script to find what computer locked a specified AD account
# Written by Greg Rowe (April 2017)

Param
(
    $UserName
)


$PDCEmulator = ( [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() ).Domains.PdcRoleOwner.Name
Invoke-Command -ComputerName $PDCEmulator -ArgumentList $UserName -ScriptBlock `
{
    If( $UserName ) { $Events = Get-WinEvent -FilterHashtable @{ Logname='Security';ID=4740 } | Where-Object { $_.Message -like "*$UserName" } }
    Else            { $Events = Get-WinEvent -FilterHashtable @{ Logname='Security';ID=4740 } }
    
    ForEach($Event in $Events)
    {
        ( $Event.Message -split 'Account That Was Locked Out:' )[1] | Select `
            @{
                Name       = 'TimeCreated'
                Expression = { $Event.TimeCreated }
            }, `
            @{
                Name       = 'AccountName'
                Expression = { ( ( [regex]::Match($Message,'[\n\r].*Account Name:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
            }, `
            @{
                Name       = 'SourceComputer'
                Expression = { ( ( [regex]::Match($Message,'[\n\r].*Caller Computer Name:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
            }
    }
} | Select TimeCreated,AccountName,SourceComputer