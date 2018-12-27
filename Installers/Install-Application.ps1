Function Install-Application
{
    # Installs only the following application types: EXE, MSI, MSU
    # Returns exit code if attempted installation fails
    # Does not return anything if installation succeeds
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipeline = $True )]
        $Path
    )

    Begin {}
    Process
    {
        $File      = Split-Path $Path -Leaf
        $Extension = [System.IO.Path]::GetExtension( $File )

        # Set process parameters
        If ( $Extension -eq '.EXE' -or $Extension -eq '.MSI' )
        {
            $ProcessParams = @{
                FilePath     = $Destination
                ArgumentList = @( '/quiet', '/norestart' )
            }
        }
        ElseIf ( $Extension -eq '.MSU' )
        {
            $ProcessParams = @{
                FilePath     = "$env:SystemRoot\SysWOW64\wusa.exe"
                ArgumentList = @( $Path, '/quiet', '/norestart' )
            }
        }
        Else
        {
            Write-Warning "[ Install ] [ $File ] does not appear to be an EXE, MSI, or MSU. Abort installation"
            Return
        }

        # Execute applictaion
        Write-Verbose "[ Install ] [ $File ] Start installation"
        $Process = Start-Process @ProcessParams -Wait -PassThru

        # Output success/failure codes
        If ( $Process.ExitCode -eq 0 )
        {
            Write-Verbose "[ Install ] [ $File ] Installation complete"
        }
        Else
        {
            Write-Warning "[ Install ] [ $File ] Installation failed! Exit code: $( $Process.ExitCode )"
            Return $Process.ExitCode
        }

        Write-Verbose "[ Install ] [ $File ] Installation complete"
    }
    End {}
}
