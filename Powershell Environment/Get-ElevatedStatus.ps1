Function Get-ElevatedStatus
{
    # Checks if current scope is running as administrator
    # Returns True if elevated, False if not

    # Get current user principal
    $Principal = New-Object System.Security.Principal.WindowsPrincipal ( [System.Security.Principal.WindowsIdentity]::GetCurrent() )
    
    # Check for local admin privelages
    If ( $Principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator ) -eq $True )
    {
        Return $True 
    }
    Else
    {
        Return $False
    }
}
