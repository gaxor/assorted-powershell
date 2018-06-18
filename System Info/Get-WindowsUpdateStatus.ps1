# Script to query all domain servers for specified Windows Updates.
# Script does not work
# Written by Greg Rowe (May 2017)

$HotFixIDs       = @( `
	'KB3205409',
	'KB3210720',
	'KB3210721',
	'KB3212646',
	'KB3213986',
	'KB4012212',
	'KB4012213',
	'KB4012214',
	'KB4012215',
	'KB4012216',
	'KB4012217',
	'KB4012218',
	'KB4012220',
	'KB4012598',
	'KB4012606',
	'KB4013198',
	'KB4013389',
	'KB4013429',
	'KB4015217',
	'KB4015438',
	'KB4015546',
	'KB4015547',
	'KB4015548',
	'KB4015549',
	'KB4015550',
	'KB4015551',
	'KB4015552',
	'KB4015553',
	'KB4015554',
	'KB4016635',
	'KB4019213',
	'KB4019214',
	'KB4019215',
	'KB4019216',
	'KB4019263',
	'KB4019264',
	'KB4019472'
)
$QueryResults    = @()
$PDCEmulator     = ( [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() ).Domains.PdcRoleOwner.Name
$DomainComputers = Invoke-Command -ComputerName $PDCEmulator -ScriptBlock `
{ ( Get-ADComputer -Filter { ( OperatingSystem -Like 'Windows*' ) -and ( OperatingSystem -Like '*Server*' ) } ).DNSHostName }

ForEach ( $Computer in $DomainComputers )
{
	$QueryResults += New-Object PSCustomObject -Property `
	@{
		'ComputerName' = $Computer
		'HotFixStatus' = @()
		'Ping'         = @{}
		'WinRM'        = @{}
		'Error'        = @{}
	}
	Start-Job -Name $Computer -ArgumentList $Computer,$HotFixIDs -ScriptBlock `
	{
		Param( $Computer,$HotFixIDs )
		$Output         = New-Object PSCustomObject | Select Ping,WinRM,Missing,Present,Error
		$Output.Ping    = Test-NetConnection -ComputerName $Computer -InformationLevel Quiet
		$Output.WinRM   = Test-NetConnection -ComputerName $Computer -CommonTCPPort WINRM -InformationLevel Quiet
		Try
		{
			$Output.Present = Get-HotFix -ComputerName $Computer
			If ( $Output.Present )
			{
				ForEach ( $Fix in $Hotfixes )
				{ If ( $HotFixIDs -contains $_ ) { $HotFixIDs.Remove( $_ ) } }
				$Output.MissingHotfixes = $HotFixIDs
			}
			Else
			{
				#$Output.Missing = 'All Present'
			}
		}
		Catch
		{
			$Output.Error = $Error[0].Exception.Message
		}
		Write-Output $Output
	}
}

While ( Get-Job -State Running )
{
    $TotalJobs   = ( Get-Job ).Count
    $RunningJobs = ( Get-Job -State Running ).Count
    Write-Progress `
	 -Activity 'Waiting for queries to return data' `
	 -CurrentOperation "Queries remaining: $RunningJobs" `
	 -PercentComplete ( $RunningJobs / $TotalJobs * 100 )
    Start-Sleep -m 500
}

ForEach ( $Computer in $DomainComputers )
{
	Try
	{
		$Job = Get-Job -Name $Computer | Receive-Job -Keep | Select * -ExcludeProperty RunspaceId
		If ( $Job.HotFixIDs )
		{
			$QueryResults += $Job | Select `
			HotFixIDs, `
			InstalledOn, `
			@{ Name = 'ComputerName'; Expression = { $Computer } }
		}
		Else
		{
			$QueryResults += $Job | Select `
			@{ Name = 'ComputerName'; Expression = { $Computer } },
			@{ Name = 'Error';        Expression = { $Error[0].Exception.Message } },
			@{ Name = 'Failed';       Expression = { $True } }
		}
		Remove-Job -Name $Computer -ErrorAction SilentlyContinue
	}
	Catch
	{
		$QueryResults | Where { $_.ComputerName -eq $Computer }
	}
}