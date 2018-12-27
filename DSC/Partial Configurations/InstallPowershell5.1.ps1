
# Install Powershell 5.1 KB3191564
Script InstallPowerShell
{
    GetScript = 
    {
        @{ Result = "PowerShell Version: $( $PSVersionTable.PSVersion )" }
    }
    TestScript = 
    {
        # Output is True if installed Powershell is 5.1 or greater
        $PSVersionTable.PSVersion -ge [Version] 5.1
    }
    SetScript = 
    {
        # Install Powershell 5.1
        Start-Process `
            -FilePath "$env:SystemRoot\SysWOW64\wusa.exe" `
            -ArgumentList ( 'C:\DSC\Win8.1AndW2K12R2-KB3191564-x64.msu', '/quiet', '/norestart' ) `
            -Wait
    }
}
