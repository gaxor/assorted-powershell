
# Install .NET Framework 4.6.1
Script InstallDotNet
{
    GetScript = 
    {
        @{ Result = ".NET Version: $( ( Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' ).Version )" }
    }
    TestScript = 
    {
        # Check installed .NET version
        $DotNet = ( Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' ).Release

        # Output is True if installed .NET is v4.6.1 (394254) or greater
        $DotNet -ge 394254
    }
    SetScript = 
    {
        $Uri = "https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe" # DotNet 4.6.1
        $FileName = Split-Path $Uri -Leaf
        $Destination = Join-Path $Using:OutPath, $FileName

        New-Item $Using:OutPath -ErrorAction SilentlyContinue

        # Download the Hotfix
        Start-BitsTransfer -Source $Uri -Destination $Destination

        # Install .NET
        Start-Process $Destination -ArgumentList ( '/quiet', '/norestart' ) -Wait
    }
}
