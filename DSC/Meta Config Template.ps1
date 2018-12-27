Param
(
    $ComputerName = 'localhost',
	$MofPath      = "$env:TEMP\DSC"
)

[DSCLocalConfigurationManager()]
Configuration MetaConfigurationTemplate
{
	Node $ComputerName
	{
		Settings
		{
			ConfigurationMode              = 'ApplyAndAutoCorrect'
			ConfigurationModeFrequencyMins = 15
			RefreshMode                    = 'Push'
			RebootNodeIfNeeded             = $False
		}
	}
}

MetaConfigurationTemplate -OutputPath $MofPath

Set-DscLocalConfigurationManager -ComputerName $ComputerName -Path $MofPath -Force -Verbose
