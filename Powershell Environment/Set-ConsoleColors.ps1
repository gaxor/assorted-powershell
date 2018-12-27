# Sets foreground and background console colors
Function Set-ConsoleColors
{
    Param
    (
        $VerboseColor = 'Cyan',
        $WarningColor = 'Yellow',
        $ErrorColor   = 'Red'
    )
    
    # Set event background to match current console background
    Switch( $Host.Name )
    {
        'ConsoleHost'
        {
            $Host.PrivateData.VerboseBackgroundColor = $Host.UI.RawUI.BackgroundColor
            $Host.PrivateData.WarningBackgroundColor = $Host.UI.RawUI.BackgroundColor
            $Host.PrivateData.ErrorBackgroundColor   = $Host.UI.RawUI.BackgroundColor
        }
        'Windows PowerShell ISE Host'
        {
            $Host.PrivateData.VerboseBackgroundColor = $Host.PrivateData.ConsolePaneBackgroundColor
            $Host.PrivateData.WarningBackgroundColor = $Host.PrivateData.ConsolePaneBackgroundColor
            $Host.PrivateData.ErrorBackgroundColor   = $Host.PrivateData.ConsolePaneBackgroundColor
        }
    }

    # Set event foreground colors
    $Host.PrivateData.VerboseForegroundColor = $VerboseColor
    $Host.PrivateData.WarningForegroundColor = $WarningColor
    $Host.PrivateData.ErrorForegroundColor   = $ErrorColor
}
