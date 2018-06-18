# Script to find where & why a domain account was locked out
# Written by Greg Rowe (2017)
# This script is not done

#Requires -Version 5 -Module ActiveDirectory

Param
(
    [Parameter(Mandatory=$True)]
    $UserName
)

$DomainControllers =   [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() | ForEach-Object { $_.DomainControllers } | ForEach-Object { $_.Name }
$PDCEmulator       = ( [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() ).Domains.PdcRoleOwner.Name

Function Get-LockOutStatus
{
    # Get lockout status from Domain Controllers
    Foreach( $DC in $DomainControllers )
    {
        Invoke-Command -ComputerName $DC.HostName -AsJob -ArgumentList $UserName -ScriptBlock `
        {
            Param( $UserName )

            $LockOutInfo = @()
            $UserInfo    = Get-ADUser -Identity $UserName -Properties AccountLockoutTime, LastBadPasswordAttempt, BadPwdCount, LockedOut
            
            If( $UserInfo.LastBadPasswordAttempt )
            {    
                $LockOutInfo = New-Object -TypeName PSCustomObject -Property `
                @{
                    Name                   = $UserInfo.SamAccountName
                    SID                    = $UserInfo.SID.Value
                    LockedOut              = $UserInfo.LockedOut
                    BadPwdCount            = $UserInfo.BadPwdCount
                    BadPasswordTime        = $UserInfo.BadPasswordTime            
                    DomainController       = $env:COMPUTERNAME
                    AccountLockoutTime     = $UserInfo.AccountLockoutTime
                    LastBadPasswordAttempt = $UserInfo.LastBadPasswordAttempt
                }
                Write-Output $LockOutInfo
            }
        }
    }

    Get-Job | Wait-Job | Receive-Job | Select Name, SID, LockedOut, BadPwdCount, BadPasswordTime, DomainController, AccountLockoutTime, LastBadPasswordAttempt
    Remove-Job *
}

Function Get-LockOutEvent
{
    # Get lockout events from PDC Emulator
    Invoke-Command -ComputerName $PDCEmulator -ArgumentList $UserName -ScriptBlock `
    {
        Param( $UserName )

        $Output = @()
        $Events = Get-WinEvent -FilterHashtable @{ Logname='Security';ID=4740 }
    
        ForEach( $Event in $Events )
        {
            $Message = ( $Event.Message -split 'Account That Was Locked Out:' )[1]
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
                Name       = 'SourceClient'
                Expression = { ( ( [regex]::Match($Message,'[\n\r].*Caller Computer Name:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
            }
        }
        Write-Output $Output
    } | Select TimeCreated, AccountName, SourceClient
}

Function Get-LogonFailures
{
    # Get RDP logon failures from computer(s) in 
    $UserName = '*'
    $e = Invoke-Command -ComputerName 'COMPUTERNAME' -ArgumentList $UserName -ScriptBlock `
        {
            Param( $UserName )

            Get-WinEvent -FilterHashtable @{ Logname='Security';ID=4625 }
        }
    $e[0] | Select `
    @{
        Name       = 'TimeCreated'
        Expression = { $a.TimeCreated }
    }, `
    @{
        Name       = 'SecurityID'
        Expression = { ( ( [regex]::Match( $a.Message, '[\n\r].*Security ID:\s*([^\n\r]*)' ).Value ).Split( ':' )[1] ).Trim() }
    }, `
    @{
        Name       = 'AccountName'
        Expression = { ( ( [regex]::Match( $a.Message, '[\n\r].*Account Name:\s*([^\n\r]*)' ).Value ).Split( ':' )[1] ).Trim() }
    }
}

# Get logon status from offending computer(s), log user off if disconnected

# Get stored credentials from offending computers
$Creds = ( ( CMDKEY /List | Select-String -Pattern 'target: ' | Out-String -Stream ).Trim() ).TrimStart( 'Target: ' ) | ConvertFrom-String -Delimiter ':target=' -PropertyNames TargetType,Account

# Have a way to remove selected cred(s)
$Store = New-Object System.Security.Cryptography.X509Certificates.X509Store( [System.Security.Cryptography.X509Certificates.StoreName]::Root,"localmachine" )