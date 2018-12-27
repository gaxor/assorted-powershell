[CmdletBinding()]
Param
(
    $VerbosePreference = 'Continue'
)

# Declare required DSC modules and (optional) versions
$DscModules = @(
    @{
        Name  = 'xWebAdministration'
        Version = '1.18.0.0'
    }
    @{
        Name  = 'cNtfsAccessControl'
        Version = '1.3.0'
    }
    @{
        Name  = 'xCertificate'
        Version = '3.0.0.0'
    }
)

# Import functions
Write-Verbose '[ Controller ] Import functions from file'
Set-Location $PSScriptRoot
. .\Functions.ps1

# Set console text colors
Write-Verbose '[ Controller ] Set console colors'
Set-ConsoleColors

# # Temporarily bypass execution policy
# Set-TempExecPolicy -Begin

# Populate ConfigurationData variable
Write-Verbose "[ Controller ] Import configuration data from file"
$ConfigurationData = Import-Variables -FilePath '..\Data.psd1'

# Install required Roles/Features (offline source)
$FeatureSource = "E:\sxs"
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
    'Web-App-Dev'
    'Web-Asp-Net'
    'Web-Asp-Net45'
    'Web-Basic-Auth'
    'Web-Common-Http'
    'Web-Default-Doc'
    'Web-Dir-Browsing'
    'Web-Filtering'
    'Web-Ftp-Server'
    'Web-Ftp-Service'
    'Web-Health'
    'Web-Http-Errors'
    'Web-Http-Logging'
    'Web-Http-Redirect'
    'Web-IP-Security'
    'Web-ISAPI-Ext'
    'Web-ISAPI-Filter'
    'Web-Lgcy-Mgmt-Console'
    'Web-Metabase'
    'Web-Mgmt-Compat'
    'Web-Mgmt-Console'
    'Web-Mgmt-Tools'
    'Web-Net-Ext'
    'Web-Net-Ext45'
    'Web-ODBC-Logging'
    'Web-Performance'
    'Web-Request-Monitor'
    'Web-Security'
    'Web-Server'
    'Web-Stat-Compression'
    'Web-Static-Content'
    'Web-WebServer'
)

$Installed = Get-WindowsFeature | Where-Object { $_.Installed -eq $true }
ForEach ($Feature in $Features)
{
    If ( $Feature -notin $Installed.name )
    {
        Write-Warning $Feature
        Install-WindowsFeature -Name $Feature -Source $FeatureSource -Verbose
    }
}

# DSC-Create Prerequisite: Powershell 5
If ( ( Get-Powershell5InstallState ) -eq $False )
{
    Write-Warning '[ Controller ] [ Powershell5 ] State: Not Installed. Installing...'
    $PSUri       = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2017/03/windowsblue-kb3191564-x64_91d95a0ca035587d4c1babe491f51e06a1529843.msu'
    $PSInstaller = Get-WebFile -Uri $PSUri

    If ( ( Test-Path $PSInstaller ) -eq $False )
    {
        Write-Warning "[ Controller ] [ Powershell5 ] [ $FileName ] Download failed"
        Write-Warning "[ Controller ] Please download and install Powershell 5.1 ($PSUri)."

        Write-Output '[ Controller ] Press any key to exit'
        $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
        Exit
    }
    Else
    {
        Write-Verbose '[ Controller ] [ Powershell5 ] Install...'
        & Wusa.exe $PSInstaller /quiet /norestart | Out-String
        Write-Verbose '[ Controller ] [ Powershell5 ] Installation complete'
        Write-Warning '[ Controller ] [ Powershell5 ] Please restart your system and run this script again.'

        Set-TempExecPolicy -End
        Write-Verbose '[ Controller ] Restart computer now!'
        Restart-Computer -Force -Confirm
        Exit
    }
}

# Get credentials
Write-Verbose '[ Controller ] Get credentials from user...'
$SqlCredential         = Get-Credential -Message 'Enter credentials for (IIS App Pool) and (SQL connection):'
$CertificateCredential = Get-Credential -UserName $ConfigurationData.CertificatePath.Split('\')[-1] -Message 'Enter the certificate password:'
$AppPoolCredential     = Get-Credential -Message 'Enter the AppPool user credentials:'
$MongoCredential       = Get-Credential -Message 'Enter MongoDB user credentials:'

# DSC-Create Prerequisite: Dsc Resources
Install-NuGet
Set-PSGalleryTrust -Policy Trusted
ForEach ( $Module in $DSCModules )
{
    $ProgressPreference = 'SilentlyContinue'
    Install-DscModule -Module $Module.Name -Version $Module.Version
    Uninstall-DeprecatedModule -Name $Module.Name -Version $Module.Version
    $ProgressPreference = 'Continue'
}

# Install DSC Feature
Write-Verbose "[ DSCFeature ] Install..."
If ( ( Install-DscFeature ) -eq $True )
{
    Write-Verbose "[ DSCFeature ] Install successful"
    Write-Verbose "[ EncryptionCert ] Get thumbprint..."
    $DscCertificate = Get-DscCertificate

    If ( $DscCertificate )
    {
        Write-Verbose "[ EncryptionCert ] Thumbprint: $( $DscCertificate.Thumbprint )"
    }
    Else
    {
        Write-Verbose "[ EncryptionCert ] Install cert..."
        $DscCertificate = Install-DscCertificate
        Write-Verbose "[ EncryptionCert ] Thumbprint: $( $DscCertificate.Thumbprint )"
    }
}
Else
{
    Write-Warning "[ DSCFeature ] Install failed"
}

# Populate connection strings file
$Content = Get-Content -Path .\connectionStrings.config -Raw

# Add content to configuration data
$ConfigurationData.ConnectionStrings = $Content

# Unzip website files before DSC runs; this will potentially greatly speed up the process
If ( ( Test-Path ( Join-Path $ConfigurationData.WebsitePath 'Website' ) ) -eq $False )
{
    Write-Verbose '[ Controller ] Extracting site files, this may take some time...'
    Expand-Archive -Path ..\SitecoreDefaultFiles.zip -DestinationPath $ConfigurationData.WebsitePath -ErrorAction SilentlyContinue
}

# Import DSC configurations
Write-Verbose '[ Controller ] Import DSC LCM'
. .\MetaConfiguration.ps1

Write-Verbose '[ Controller ] Import DSC configuration'
. .\SitecoreConfiguration.ps1

# Push Local Configuration Manager settings
Write-Verbose "[ DSCLCM ] Create settings"
MetaConfiguration -CertificateThumbprint $DscCertificate.Thumbprint

Write-Verbose "[ DSCLCM ] Push settings"
Set-DscLocalConfigurationManager -Path .\MetaConfiguration

# Push DSC Configurations
Write-Verbose "[ DSCConfiguration ] Create configuration"
SitecoreConfiguration -ConfigurationData $ConfigurationData

Write-Verbose "[ DSCConfiguration ] Push configuration"
Start-DscConfiguration -Path .\SitecoreConfiguration -Force -Wait

# Delete non-encrypted configuration files
Get-ChildItem -Include '*.mof','*.mof.error' -Recurse | Remove-Item
