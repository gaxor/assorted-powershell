
# Set up FTP Server
Script SetupFTP
{
    DependsOn = '[xWebSite]Sitecore'
    GetScript = 
    {
        @{ Result = '' }
    }
    TestScript = 
    {
        # Check if FTP has to be installed by parameters
        Return $True # Skip FTP for now
    }
    SetScript = 
    {
        # Ftp site creation
        $Target               = "C:\inetpub\ftproot"
        $FtpUserName          = "username"
        $FtpSiteTitle         = "domain.com"
        $Ftpprotocol          = "ftp"
        $BindingInformation   = "*:21:"
        $Bindings             = '@{protocol="' + $Ftpprotocol + '";bindingInformation="'+ $BindingInformation +'"}'
        $VirtualDirectoryPath = "IIS:\Sites\$FtpSiteTitle"

        Import-Module WebAdministration
        # Create the FTP folder if it doesnt exist.
        If ( !( Test-Path "$Target" ) )
        {
            New-Item $Target -itemType directory
        }

        # Remove ftp site if exists
        Remove-Item IIS:\Sites\$FtpSiteTitle -Recurse -ErrorAction SilentlyContinue

        Write-Host "...Creating FTP Site"
        New-Item IIS:\Sites\$FtpSiteTitle -bindings $Bindings -physicalPath $Target -Verbose:$False | Out-Null
        
        # Map a folder to the FTP site...
        New-WebVirtualDirectory -Site $FtpSiteTitle -Name "VirtualFolder" -PhysicalPath $Target

        # Set the permissions...
        # Splatting Add-WebConfiguration function (Allow Specific User to Read/Write)
        $ConfigurationParameters = @{
            Filter   = '/System.FtpServer/Security/Authorization'
            Value    = @{
                AccessType  = "Allow"
                Users       = $FtpUserName
                Permissions = "Read, Write"
            }
            PsPath   = 'IIS:'
            Location = $ftpSiteTitle
        } 
        Add-WebConfiguration @ConfigurationParameters

        # Splatting Add-WebConfiguration function (Allow All Users to Read)
        $ConfigurationParameters = @{
            Filter   = '/System.FtpServer/Security/Authorization'
            Value    = @{
                AccessType  = "Allow"
                Users       = "All Users"
                Permissions = "Read"
            }
            PsPath   = 'IIS:'
            Location = $ftpSiteTitle
        }

        Add-WebConfiguration @ConfigurationParameters

        # Allow SSL connections 
        Set-ItemProperty $virtualDirectoryPath -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
        Set-ItemProperty $virtualDirectoryPath -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

        # Enable Basic Authentication
        Set-ItemProperty $virtualDirectoryPath -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $True
    }
}
