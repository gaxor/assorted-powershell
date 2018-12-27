Param
(
	<# -----  Path to configuration data file ----- #>
	# Variable Requirements:
	# - Mandatory (cannot be left empty)
	# - Must be path to a DSC configuration data file (*.psd1)
	# - Must be enclosed in single or double quotes
	#
	# Example:
	#	'~\Desktop\DscConfigData.psd1'

	[ValidateScript( { ( Test-Path $_ ) -AND ( ( Get-Item $_ ).Extension -EQ '.psd1' ) } )]
	[String]
	$ConfigurationDataFile,
	
	<# -----  Path to save MOF files ----- #>
	# Variable Requirements:
	# - Must be a local directory path
	# - Must be enclosed in single or double quotes
	#
	# Example:
	#	'C:\temp\DSCFiles'

	[String]
	$MofPath = "$env:TEMP\DSC"
)

$RequiredDSCModules =
@(
	'xPSDesiredStateConfiguration'
	'xWebAdministration'
	'cNtfsAccessControl'
)

# Allow powershell scripts to run uninhibited for current server
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Unrestricted -Force

# Install NuGet package provider
If ( !( Get-PackageProvider -Name NuGet ) )
{
	Install-PackageProvider -Name NuGet -Force
}

# Set PSGallery as trusted source
If ( !( Get-PSRepository -Name PSGallery ).InstallationPolicy )
{ Set-PSRepository -Name PSGallery -InstallationPolicy Trusted }

# Install DSC modules locally (local machine creates MOF files)
$RequiredDSCModules | ForEach {
	If ( !( Get-DscResource -Module $_ ) )
	{ Install-Module -Name $_ -Force }
}

# DSC LCM (Local Configuration Manager) configuration declaration
[DSCLocalConfigurationManager()]
Configuration MetaConfiguration
{
	Node localhost
	{
		Settings
		{
			ConfigurationMode              = 'ApplyAndMonitor'
			ConfigurationModeFrequencyMins = 15
			RefreshMode                    = 'Push'
			RebootNodeIfNeeded             = $True
		}
	}
}

# DSC configuration declaration
Configuration IISWebServer
{
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xPSDesiredStateConfiguration
	Import-DscResource -ModuleName xWebAdministration
	Import-DscResource -ModuleName cNtfsAccessControl

	Node localhost
	{
		$Features =
		@(
			'DSC-Service'
			'NET-Framework-Core'
			'NET-Framework-Features'
			'NET-Framework-45-Core'
			'NET-Framework-45-Features'
			'RSAT'
			'RSAT-Feature-Tools'
			'RSAT-Role-Tools'
			'RSAT-SMTP'
			'SMTP-Server'
			'SNMP-Service'
			'Telnet-Client'
			'Web-Basic-Auth'
			'Web-Common-Http'
			'Web-Default-Doc'
			'Web-Health'
			'Web-Http-Errors'
			'Web-Http-Logging'
			'Web-Metabase'
			'Web-Mgmt-Compat'
			'Web-Mgmt-Console'
			'Web-Mgmt-Tools'
			'Web-Net-Ext'
			'Web-Net-Ext45'
			'Web-Performance'
			'Web-Request-Monitor'
			'Web-Security'
			'Web-Server'
			'Web-Stat-Compression'
			'Web-Static-Content'
			'Web-WebServer'
		)

		# Install Windows features
		ForEach ( $Feature in $Features )
		{
			WindowsFeature $Feature
			{
				Ensure = 'Present'
				Name   = $Feature
			}
		}

		# Copy website files
		File WebsiteFiles
		{
			Ensure          = 'Absent'
			Type            = 'File'
			DestinationPath = 'C:\inetpub\wwwroot\index.html'
		}
		
		# Create site in IIS
		xWebsite DefaultWebSite
		{
			Name         = 'Default Web Site'
			Ensure       = 'Present'
			PhysicalPath = 'C:\inetpub\wwwroot'
			BindingInfo  =
			MSFT_xWebBindingInformation
			{
				Protocol  = 'HTTP'
				IPAddress = '*'
				HostName  = 'domain.com'
			}
		}
			
		# Create app pool
		xWebAppPool AppPool
		{
			DependsOn             = '[xWebsite]DefaultWebSite'
			Ensure                = 'Present'
			Name                  = 'DefaultAppPool'
			IdentityType          = 'ApplicationPoolIdentity'
			LoadUserProfile       = $False
			managedRuntimeVersion = 'v4.0'
		}
		
		# Set NTFS permissions
		cNtfsPermissionEntry "NTFSPermissionsDefaultWebSite"
		{
			DependsOn                = '[File]WebsiteFiles', '[xWebsite]DefaultWebSite'
			Ensure                   = 'Present'
			Path                     = 'C:\inetpub\wwwroot'
			Principal                = 'IIS AppPool\DefaultAppPool'
			AccessControlInformation =
			@(
				cNtfsAccessControlInformation
				{
					AccessControlType  = 'Allow'
					FileSystemRights   = 'ReadAndExecute'
					Inheritance        = 'ThisFolderSubfoldersAndFiles'
					NoPropagateInherit = $False
				}
			)
		}
	}
}

# Create LCM MOF
MetaConfiguration -OutputPath $MofPath

# Push LCM configuration
Set-DscLocalConfigurationManager -Path $MofPath -Force -Verbose

# Create DSC MOF
IISWebServer -ConfigurationData $ConfigurationData -OutputPath $MofPath

# Push DSC configuration
Start-DscConfiguration -Path $MofPath -Force -Wait -Verbose
