# Commandlet to start or stop an AWS instance after notifying Nagios
# Written by Greg Rowe (April 2017)

#Requires -Modules AWSPowerShell
Param
(
    [Parameter(Mandatory=$True)]
    [ValidateSet('COMPUTER1','COMPUTER2')]
    [String]$ComputerName,
    
    [Parameter(Mandatory=$True)]
    [ValidateSet('Start','Stop')]
    [String]$Action
)

Function Get-NagiosCmd
{
    # Returns Nagios command(s). List of commands: https://docs.icinga.com/latest/en/cgiparams.html#idp190107760
    Param($Action)

    Switch($Action)
    {
        Start { Write-Output 15,47 }
        Stop  { Write-Output 16,48 }
    }
}

Function Invoke-NagiosCmd
{
    # Changes Nagios Notification Settings
    Param($NagiosCmd)

    ForEach($Cmd in $NagiosCmd)
    {
        $WebPost = Invoke-WebRequest `
            -Uri 'https://NAGIOSDOMAIN.TLD/nagios/cgi-bin/cmd.cgi' `
            -Body @{cmd_typ=$Cmd;host=$ComputerName;ahas=$True;cmd_mod=2} `
            -Method POST -ContentType 'application/x-www-form-urlencoded'
        If($WebPost.RawContent.Contains('Your command request was successfully submitted to Nagios for processing.'))
        {
            Write-Output 'Success'
        }
        Else
        {
            Write-Output 'Failure'
        }
    }
}

Function Undo-NagiosInvoke
{
    Param($Action,$ExitCode)

    Switch($Action,$ExitCode)
    {
        Start { $NagiosCmd = Get-NagiosCmd -Action 'Stop' }
        Stop  { $NagiosCmd = Get-NagiosCmd -Action 'Start' }
    }
    Invoke-NagiosCmd -NagiosCmd $NagiosCmd
    If($ExitCode){ [Environment]::Exit($ExitCode) }
}

Function Invoke-InstanceState
{
    # Changes AWS Server State
    Param($InstanceID,$Action)

    Switch($Action)
    {
        Start { Start-EC2Instance -InstanceId $InstanceID }
        Stop  { Stop-EC2Instance  -InstanceId $InstanceID }
    }
}

# Set chosen server's AWS instance ID
Switch($ComputerName)
{
    COMPUTER1 { $InstanceID = 'i-COMPUTER1' }
    COMPUTER2 { $InstanceID = 'i-COMPUTER2' }
}

# Set AWS credentials
Set-AWSCredentials -AccessKey 'ACCESSKEY' -SecretKey 'SECRETKEY'
Set-DefaultAWSRegion -Region us-east-1

$NagiosCmd     = Get-NagiosCmd -Action $Action
$NagiosResult += Invoke-NagiosCmd -NagiosCmd $NagiosCmd

If($NagiosResult -contains 'Success' -and $NagiosResult -notcontains 'Failure')
{
    Try   { Invoke-InstanceState -InstanceID $InstanceID -Action $Action }
    Catch { Undo-NagiosInvoke -Action $Action -ExitCode 352 <# ERROR_FAIL_RESTART #> | Out-Null }
}
Else
{
    Undo-NagiosInvoke -Action $Action -ExitCode 746 <# ERROR_PRIMARY_TRANSPORT_CONNECT_FAILED #> | Out-Null
}