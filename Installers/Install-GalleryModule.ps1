Function Install-GalleryModule
{
    # Installs Module from PowerShellGallery.com
    # Returns True when installed, False if install fails
    [CmdletBinding()]
    Param
    (
        [String] $Module
    )

    Import-Module $Module

    If ( Get-Module -Name $Module )
    {
        Write-Verbose "[ PackageManager ] [ $Module ] State: Installed"
        Return $True
    }
    Else
    {
        Try
        {
            Write-Verbose "[ PackageManager ] [ $Module ] Installing..."
            Install-Module -Name $Module -Force
            Write-Verbose "[ PackageManager ] [ $Module ] Installation successful"
            Return $True
        }
        Catch
        {
            Write-Warning "[ PackageManager ] [ $Module ] $( $Error[0].Exception.Message )"
            Return $False
        }
    }
}
