$ConsoleColors = [System.Enum]::GetValues('System.ConsoleColor')

ForEach ( $Color in $ConsoleColors )
{
    $Progress = @{
        Activity        = "Listing Available Colors ($( $ConsoleColors.Count ) different colors)"
        Status          = $Color
        PercentComplete = ( [Array]::IndexOf( $ConsoleColors, $Color ) / $ConsoleColors.Count * 100 )
    }
    Write-Progress @Progress

    $ConsoleColors | ForEach { Write-Host " [ $Color ] " -BackgroundColor $Color -ForegroundColor $_ }
    Start-Sleep -Seconds 1
}

