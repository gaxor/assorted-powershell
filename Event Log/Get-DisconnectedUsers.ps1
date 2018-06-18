<#
    .Synopsis
        Gets a report of machines specified users have forgotten to log out of (session disconnected).
    .DESCRIPTION
        Syntax
            Get-DisconnectedUsers ComputerName [[UserName] AND/OR [GroupName]] [-Email] [SMTPServer] [FromAddress] [Credential]
            
            - Each computer is queried in parallel via background jobs
            - Requires ActiveDirectory module.
            - Email addresses are pulled from Active Directory.
    .EXAMPLE
        Get-DisconnectedUsers -CompuerName 'DC1','DC2' -UserName 'JSmith' -Email
            - Queries DC1 & DC2.
            - Emails disconnected sessions to JSmith.
    .NOTES
        Written by Gaxor (December 2016)
#>

Param(
    [Parameter(Position=0,Mandatory=$True)]
    [Array]$ComputerName,
    [Parameter(Position=1)]
    [Array]$UserName,
    [Parameter(Position=2)]
    [Array]$GroupName,
    [Parameter(Position=3)]
    [Switch]$Email,
    $MailServer,
    $From,
    $ErrorsTo,
    $Credential
)
#$ComputerName = Get-ADComputer -SearchBase 'OU=Servers,dc=Domain,dc=tld' -Filter '*' | Select -ExpandProperty Name
#$ComputerName = 'server1' #,'server','server'
#$GroupName = 'domain admins'
#$Email = $True

$Jobs                = @()
$DisconnectedList    = @()
$ConnectionErrorList = @()
$EmailErrorList      = @()
$GetLoggedOnUser     = {
    Param(
        [Parameter(Position=0,Mandatory=$True)]
        [alias('ComputerName')]
        $Computer
    )

    $Query = quser /server:$Computer 2>&1

    If(!$Query.Exception){
        $Output = $Query | Select-Object -Skip 1 | ForEach-Object{
            $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
            If ($CurrentLine[2] -eq 'Disc'){
                $HashProps = [Ordered]@{
                    UserName     = $CurrentLine[0]
                    ComputerName = $Computer
                    State        = $CurrentLine[2]
                    IdleTime     = $CurrentLine[3]
                }
                If($HashProps.IdleTime -eq 'none'){
                    [DateTime]$LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '
                    $T            = [TimeSpan]::FromTicks((get-date).Ticks-$LogonTime.Ticks)
                    $HashProps.IdleTime  = "$($T.Days)+$($T.Hours):$($T.Minutes):$("{0:D2}" -f $T.Seconds)"
                }
                New-Object -TypeName PSCustomObject -Property $HashProps
            }
        }
    }
    Else{
        If($Query.Exception.Message -like '*No User exists*'){
            Return
        }
        $Output = New-Object -TypeName PSCustomObject -Property @{
            ComputerName = $Computer
            ConnectionError = $null
        }
        If($Query.Exception.Message -like '*[5]*' -or $Query.Exception.Message -like '*[1722]*'){
            $Output.ConnectionError = ($Query.Exception.Message[1]).ToString()
        }
        Else{
            $Output.ConnectionError = [String]::Join("`r`n",$Query.Exception.Message)
            }
    }
    Write-Output $Output
}
$BodyHead = @'
<HTML>
  <HEAD>
    <META http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" /><TITLE></TITLE>
  </HEAD>
    <BODY bgcolor=""#FFFFFF"" style=""font-size: Small; font-family: TAHOMA; color: #000000""><P>
      <p>Dear <strong>USER_NAME</strong>,</p>
'@
$BodyText = @'
      <br>When using Remote Desktop to connect to computers remotely, it is customary and curteous to log off when finished.
      <br>Forgotten logon sessions often have undesired consequences, such as:
      <ul style="list-style-type:circle">
        <li>Server resources wasted</li>
        <li>"Server has exceeded the maximum number of allowed connections" error</li>
        <li>Shutdown procedures interrupted</li>
        <li>Application Memory leaks decreasing performance</li>
        <li>Runaway processes consuming CPU cycles
      </ul>
      While some of these may be uncommon, when they do occur, it negatively impacts production and wastes the team's time.
      This report will be generated Monday through Friday until further notice.
      <p>You have left yourself logged into, and disconnected from the following computers:&nbsp;</p><hr/>
'@
$BodyTable = @'
      <style>font-family: Arial; font-size: 10pt;
        TABLE{border: 1px solid black; border-collapse: collapse;}
        TH{border: 1px solid black; background: `#dddddd; padding: 5px;}
        TD{border: 1px solid black; padding: 5px;
      </style>
      <!-- Powershell-added tables below -->
'@
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SMTPUser,($SMTPPass | ConvertTo-SecureString -AsPlainText -Force)

If($Email){
    If($MailServer -eq $null){
        [String]$MailServer = (Read-Host 'Enter the name or IP of the mail server').Trim()
    }
    If($From -eq $null){
        [String]$From = (Read-Host 'Enter the email address to send from').Trim()
    }
    If($ErrorsTo -eq $null){
        [String]$ErrorsTo = (Read-Host 'Enter the email address to send errors').Trim()
		# if left blank, $errorsto = $from
    }
    If($Credential -is [Array]){
        #convert array to pscredential
    }
    If($Credential -isnot [PSCredential]){
        [PSCredential]$Credential = Get-Credential -Message "Enter SMTP credentials for mail server: $($MailServer)"
    }
    If(!$MailServer -or !$From -or !$Credential){
        $Email = $null
        Write-Output
    }
}
If($GroupName -ne $null){
    Write-Verbose 'Retrieving users from provided groups...'
    $UserName += ($GroupName | ForEach{Get-ADGroupMember $_ | Select SamAccountName} | 
        Format-Table -HideTableHeaders | Out-String -Stream | Where{$_ -ne ''} ).Trim()
}
If($UserName -eq $null){
	Write-Error 'No UserName or GroupName provided.'
    Return
}
Write-Verbose 'Querying computers for logged in users...'
Write-Verbose 'Progress bar for "querying computers" starts at 0% and finishes at 50%'
ForEach ($Computer in $ComputerName){
    Write-Progress -Activity 'Querying computers for logged in users' -CurrentOperation $Computer -PercentComplete ((($i/$ComputerName.Count)*100)/2)
    Start-Job -Name $Computer -ScriptBlock $GetLoggedOnUser -ArgumentList $Computer | Out-Null
    $i++
}
Write-Progress -Activity 'Querying computers for logged in users' -CurrentOperation $Computer -PercentComplete ((($i/$ComputerName.Count)*100)/2)

Write-Verbose 'Waiting for queries to return data...'
Write-Verbose 'Progress bar for "return data" starts at 50% and finishes at 100%'
$InitialRunningJobs = (Get-Job -State Running).Count
While(Get-Job -State Running){
    $TotalJobs       = (Get-Job).Count
    $RunningJobs     = (Get-Job -State Running).Count
    $Perc            = ($RunningJobs-$InitialRunningJobs)*(-1)
    $PercentComplete = ((($Perc/$InitialRunningJobs)*100)/2)
    Write-Progress -Activity 'Waiting for queries to return data' -CurrentOperation "Queries remaining: $RunningJobs of $TotalJobs" -PercentComplete ($PercentComplete+50)
    Start-Sleep -m 500
}
Write-Progress -Activity 'Waiting for queries to return data' -Completed

If((Get-Job -State Running).Count -gt 0){
    Write-Verbose 'Progress bar failed; waiting for all jobs to complete...'
    Get-Job | Wait-Job | Out-Null
}

Write-Verbose 'Merging logon query data'
$Jobs = Get-Job | Select Id,Name
ForEach ($Job in $Jobs){
    $JobResults = Get-Job -Id $Job.Id | Receive-Job -Keep | Select * -ExcludeProperty RunspaceId
    If($JobResults.UserName -ne $null){$DisconnectedList += $JobResults | Where{$_.State -eq 'Disc' -and $Username -contains $_.UserName}}
    Else{$ConnectionErrorList += $JobResults | Where{$_.ConnectionError -ne $null}}
    Remove-Job -Id $Job.Id
}

If($Email){
    Write-Verbose 'Email switch is True, preparing emails...'
    $EmailList = ($DisconnectedList | 
        Sort -Property UserName -Unique | Select UserName | 
        Format-Table -HideTableHeaders | Out-String -Stream | Where{$_ -ne ''} ).Trim() | 
        Get-ADUser -Properties Mail | Select SamAccountName,Name,Mail
    
    ForEach($User in $EmailList){
        If($User.Mail -eq $null){
            $CurrentError    = "Unable to retrieve email address for $($User.Name)"
            $EmailErrorList += $CurrentError
            Write-Error $CurrentError
        }
        Else{
            Try{
                Write-Verbose "Creating email for $($User.Name)"
                $Table   = $DisconnectedList | Where{$User.SamAccountName -eq $_.UserName} | Select UserName,ComputerName,State,IdleTime | ConvertTo-Html -Fragment
                $Subject = "Disconnected RDP Sessions for $($User.Name)"
                $Body    = $BodyHead.Replace('USER_NAME',"$($User.Name)")
                $Body   += $BodyText
                $Body   += $BodyTable
                $Table   | ForEach{$Body += Write-Output "`r`n $_ `r`n      "}
                $Body   += "`r`n    </BODY>"
                $Body   += "`r`n</HTML>"

                Write-Verbose "Emailing $($User.Name): $($User.Mail)"
                $Body | Out-File -FilePath C:\temp\body.html
                Send-MailMessage -From $From -Subject $Subject -To $User.Mail -Body $Body -BodyAsHtml -Credential $Credential -SmtpServer $MailServer
            }
            Catch{
                Write-Error "Email failed to send to $($User.Name): $($User.Mail)"
                Write-Error $Error[0].Exception.Message
            }
        }
    }
    If($EmailErrorList -ne $null -or $ConnectionErrorList -ne $null){
        Write-Verbose "Creating error email."
        $Table   = $EmailErrorList | ForEach{[PSCustomObject]@{EmailError=$_}} | ConvertTo-Html -Fragment -Property EmailError
        $Table  += $ConnectionErrorList | ForEach{[PSCustomObject]@{ComputerName=$_.ComputerName;ConnectionError=$_.ConnectionError}} | ConvertTo-Html -Fragment
        $Subject = "Disconnected RDP Session Errors"
        $Body    = $BodyHead.Replace('USER_NAME',"Script Admin")
        $Body   += "<br>Below are the errors from attempting to query disconnected users:"
        $Body   += $BodyTable
        $Table   | ForEach{$Body += Write-Output "`r`n $_ `r`n      "}
        $Body   += "`r`n    </BODY>"
        $Body   += "`r`n</HTML>"
        Write-Verbose "Emailing Error Report to $($ErrorsTo)"
        Send-MailMessage -From $From -Subject 'Disconnected Users Errors' -To $ErrorsTo -Body $Body -BodyAsHtml -Credential $Credential -SmtpServer $MailServer
    }
}
Else{
    Write-Verbose 'Email switch is False; writing results to output.'
    Write-Output $DisconnectedList
}