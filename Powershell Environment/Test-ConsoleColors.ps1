# Writes verbose, warning, and default text samples to the console
Function Test-ConsoleColors
{
    Function Test-Verbose { Write-Verbose ( [GUID]::NewGuid() ) -Verbose }
    Function Test-Warning { Write-Warning ( [GUID]::NewGuid() )  }
    Function Test-Output  {    "DEFAULT: $( [GUID]::NewGuid() )" }
    
    (1..4) | ForEach {
        1..4 | ForEach { Test-Verbose }
        1..4 | ForEach { Test-Output }
        1..4 | ForEach { Test-Warning }
        Test-Verbose
        Test-Output
        Test-Warning
        Write-Error 'Testing colors'
    }
}
