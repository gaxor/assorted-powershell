Function Invoke-ElevatedPowerShell
{
    # Opens Powershell window as Administrator
    [CmdletBinding()]
    Param
    (
        $ScriptPath
    )

    If ( -not $ScriptPath )
    {
        $ScriptPath = $PSScriptRoot
    }

    $NewProcess = New-Object -TypeName Diagnostics.ProcessStartInfo -ArgumentList 'Powershell.exe'
    $NewProcess.Verb      = 'RunAs'
    $NewProcess.Arguments = $ScriptPath

    [Diagnostics.Process]::Start( $NewProcess )
}
