Function Install-Chocolatey
{
    # Installs Chocolatey PackageManager
    # Returns True once installed, False if not
    If ( $env:ChocolateyInstall )
    {
        Return $True
    }
    Else
    {
        # Test web connectivity for downloading Chocolatey
        $TcpConnection = Confirm-Connection -Website 'chocolatey.org' -Port 443
        If ( $TcpConnection -eq $True )
        {
            Try
            {
                # Download and install Chocolatey
                Write-Verbose '[ PackageManager ] [ Chocolatey ] Start Chocolatey install'
                Invoke-Expression ( ( New-Object System.Net.WebClient ).DownloadString( 'https://chocolatey.org/install.ps1' ) )
                Write-Verbose '[ PackageManager ] [ Chocolatey ] Install successful'
                Return $True
            }
            Catch
            {
                Write-Warning "[ PackageManager ] [ Chocolatey ] $( $Error[0].Exception.Message )"
                Return $False
            }
        }
        Else
        {
            Return $False
        }
    }
}
