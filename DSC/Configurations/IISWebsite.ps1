# This is not production ready

Param
(
    $ComputerName    = 'localhost',
	$SiteName        = 'TestSite2.local',
	$SourcePath      = 'D:\temp\site',
	$DestinationPath = "D:\inetpub\websites\$SiteName",
	$MofPath         = 'C:\DSCData',
	[Switch]
	$RestartAppPool  = $True
)

Configuration SitecoreWebServer
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName cNtfsAccessControl

    Node $ComputerName
    {
		$Features = @(
			'DSC-Service'
			'NET-Framework-45-Features'
			'NET-Framework-45-Core'
			'Web-Http-Redirect'
			'Web-Server'
			'Web-WebServer'
			'Web-Common-Http'
			'Web-Default-Doc'
			'Web-Http-Errors'
			'Web-Static-Content'
			'Web-Health'
			'Web-Http-Logging'
			'Web-Log-Libraries'
			'Web-App-Dev'
			'Web-Net-Ext45'
			'Web-Asp-Net45'
			'Web-Mgmt-Tools'
			'Web-Mgmt-Console'
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
		
		# Remove 'default web site'
		xWebsite DefaultSite
        {
            DependsOn       = '[WindowsFeature]Web-Server'
            Ensure          = 'Absent'
            Name            = 'Default Web Site'
        }

		# Copy website files
		File WebsiteFiles
		{
			Ensure          = 'Present'
			Type            = 'Directory'
			SourcePath      = $SourcePath
			DestinationPath = $DestinationPath
			Recurse         = $True
		}

		xWebAppPool AppPool
		{
            DependsOn = '[WindowsFeature]Web-Asp-Net45'
			Ensure    = 'Present'
			Name      = $SiteName

		}
		
		# Create site in IIS
		xWebsite $SiteName
		{
			DependsOn       = '[File]WebsiteFiles', '[xWebAppPool]AppPool'
			Ensure          = 'Present'
			Name            = $SiteName
			State           = 'Started'
			PhysicalPath    = "$DestinationPath"
			ApplicationPool = $SiteName
			BindingInfo     = MSFT_xWebBindingInformation {
				Protocol  = 'HTTP'
				Port      = 80
				IPAddress = '*'
				Hostname  = $SiteName
			}
		}

		# NTFS permissions
		cNtfsPermissionEntry NTFSPermissions
		{
			DependsOn                = '[File]WebsiteFiles', "[xWebsite]$SiteName", '[xWebAppPool]AppPool'
			Ensure                   = 'Present'
			Path                     = $DestinationPath
			Principal                = "IIS AppPool\$SiteName"
			AccessControlInformation = `
			@(
				cNtfsAccessControlInformation
				{
					AccessControlType  = 'Allow'
					FileSystemRights   = 'FullControl'
					Inheritance        = 'ThisFolderSubfoldersAndFiles'
					NoPropagateInherit = $False
				}
			)
		}

		Script RecycleAppPool
		{
			DependsOn  = "[cNtfsPermissionEntry]NTFSPermissions"
			GetScript  = { @{ Result = '' } }
			TestScript = { !$RestartAppPool }
			SetScript  = {
				Write-Verbose "Restarting AppPool: $SiteName"
				Restart-WebAppPool -Name $SiteName
			}
		}
    }
}

SitecoreWebServer -OutputPath $MofPath
Start-DscConfiguration -ComputerName $ComputerName -Path $MofPath -Force -Wait -Verbose
