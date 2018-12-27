Function Get-NamedParameters
{
    [CmdletBinding()]
    Param
    (
          [String] $ScriptPath
    )

    Invoke-Expression ( Get-Content $ScriptPath | Out-String )

    # Get the command name
    $CommandName   = $PSCmdlet.MyInvocation.InvocationName
    
    # Get the list of parameters for the command
    $ParameterList = ( Get-Command -Name $CommandName ).Parameters

    # Grab each parameter value, using Get-Variable
    ForEach ( $Parameter in $ParameterList )
    {
        Get-Variable -Name $ParameterList
    }
}

#Get-NamedParameters -ScriptPath '~\Desktop\Data.psd1'