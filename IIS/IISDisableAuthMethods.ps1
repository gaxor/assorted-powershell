# Enable/Disable IIS auth methods in site's subdirectories

$Value    = $False
$SiteName = 'domain.tld'
$BasePath = "IIS:\Sites\$SiteName\sitecore"

Import-Module WebAdministration
$SubDirectories = Get-ChildItem $BasePath -Exclude service | Where {$_.PSIsContainer} | Select -ExpandProperty Name

# Allow overriding of the security settings
[System.Reflection.Assembly]::LoadFrom("$env:systemroot\system32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
$manager = New-Object Microsoft.Web.Administration.ServerManager

# Load appHost config
$config = $manager.GetApplicationHostConfiguration()

$AuthMethods = @(
                'system.webServer/security/authentication/anonymousAuthentication'
                )

ForEach ( $AuthMethod in $AuthMethods )
{
    # Create new instance config object
    $section = $config.GetSection( $AuthMethod )
    $section.OverrideMode = 'Allow'
    $manager.CommitChanges()
}

# Set property
ForEach ( $SubDirectory in $SubDirectories )
{
    ForEach ( $AuthMethod in $AuthMethods )
    {
        Set-WebConfigurationProperty -Filter $AuthMethod -Name Enabled -Value $Value -PSPath "$BasePath\$SubDirectory" -Verbose
    }
}


#Get-WebConfigurationProperty -Name Enabled -PSPath "IIS:" -Filter "system.webServer/security/authentication/formsAuthentication"