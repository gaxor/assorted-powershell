Function Install-DotNet
{
    # Downloads and installs .NET Framework 4.6.1
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        $DownloadPath
    )
    
    $Uri         = 'https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe'
    $FileName    = Split-Path $Uri -Leaf
    $Destination = Join-Path $DownloadPath $FileName
    
    New-Item $DownloadPath -ItemType Directory -ErrorAction SilentlyContinue
    Remove-Item $Destination -ErrorAction SilentlyContinue

    # Download file
    ( New-Object System.Net.WebClient ).DownloadFile( $Uri, $Destination )

    # Install .NET
    Start-Process $Destination -ArgumentList ( '/quiet', '/norestart' ) -Wait

    # Cleanup
    Remove-Item $Destination
}
