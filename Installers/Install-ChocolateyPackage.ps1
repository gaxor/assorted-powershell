Function Install-ChocolateyPackage
{
    # Installs specific package via Chocolatey PackageManager
    [CmdletBinding()]
    Param
    (
        [String] $Package
    )

    $PackageStatus = & Choco list --local-only --exact $Package
    If ( $PackageStatus -Match '1 packages installed.' )
    {
        Write-Verbose "[ PackageManager ] [ Chocolatey ] [ $Package ] State: Installed"
    }
    Else
    {
        Try
        {
            & choco install $Package -y
            Write-Verbose "[ PackageManager ] [ Chocolatey ] [ $Package ] Install successful"
        }
        Catch
        {
            Write-Warning "[ PackageManager ] [ Chocolatey ] [ $Package ] Install failed"
        }
    }
}
