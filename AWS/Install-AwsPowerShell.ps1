# Install AWS Tools for PowerShell
If ( -not ( Get-Package -Name AWSPowerShell ) )
{
    # Add NuGet package provider
    If ( -not ( Get-PackageProvider -Name NuGet ).Name -Contains 'NuGet' )
    {
        Install-PackageProvider -Name NuGet -Force | Out-Null
    }

    # Check for local admin privelages
    $Principal = New-Object System.Security.Principal.WindowsPrincipal ( [System.Security.Principal.WindowsIdentity]::GetCurrent() )
    
    If ( $Principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator ) -eq $True )
    {
        # Install AWSPowerShell package
        Install-Package -Name AWSPowerShell -Source https://www.powershellgallery.com/api/v2/ -ProviderName NuGet -Force
    }
    Else
    {
        # Install AWSPowerShell package for current user only
        Install-Package -Name AWSPowerShell -Source https://www.powershellgallery.com/api/v2/ -ProviderName NuGet -Force -Scope CurrentUser
    }
}
