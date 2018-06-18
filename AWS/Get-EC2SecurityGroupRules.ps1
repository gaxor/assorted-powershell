# Script to list the quantity of rules per EC2 Security Group
# Written by Greg Rowe (April 2017)
#Requires -Module AWSPowerShell

$EC2SecurityGroups = Get-EC2SecurityGroup
$SecurityGroupInfo = @()

ForEach( $Group in $EC2SecurityGroups )
{
    $SecurityGroupInfo += New-Object PSCustomObject -Property `
    @{
        GroupID    = $Group.GroupId
        RuleQty    = ( $Group.IpPermission ).Count
        GroupName  = $Group.GroupName
        Rules      = $Group.IpPermission | ForEach `
        {
            If( ( $_.FromPort - $_.ToPort ) -lt 0 )
            { Write-Output "$( $_.FromPort )-$( $_.ToPort )" }
            ElseIf( $_.FromPort -eq 0 -and $_.ToPort -eq 0 )
            { }
            Else
            { Write-Output $_.FromPort }
        }
        VPC        = $Group.VpcId
    }
}

$SecurityGroupInfo | Out-GridView