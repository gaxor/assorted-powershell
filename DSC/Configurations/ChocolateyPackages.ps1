Param
(
	[String] $MofPath = "$env:TEMP\DSC"
)

# DSC configuration declaration
Configuration ChocolateyPackages
{
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName cChoco

	Node localhost
	{
		# Install Chocolatey package manager
		cChocoInstaller InstallChocolatey
        {
            InstallDir = 'C:\ProgramData\Chocolatey'
        }

		# Install .NET 4.7
        cChocoPackageInstaller 'DotNet 4.7'
        {
            Name      = 'dotnet4.7'
            Ensure    = 'Present'
            DependsOn = '[cChocoInstaller]InstallChocolatey'
			Version   = 4.7.2053.0
        }

		# Install WMF 5.1 (Powershell)
        cChocoPackageInstaller 'Powershell 5.1'
        {
            Name      = 'powershell'
            Ensure    = 'Present'
            DependsOn = '[cChocoInstaller]InstallChocolatey'
			Version   = 5.1.14409.20170510
        }
	}
}

# Create DSC MOF
ChocolateyPackages -OutputPath $MofPath

# Push DSC configuration
Start-DscConfiguration -Path $MofPath -Force -Wait -Verbose
