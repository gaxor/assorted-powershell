Function Get-ScopeName1
{
    Function Get-ScopeName2
    {
        Write-Host -ForegroundColor Magenta "Current Scope: [ $( $MyInvocation.MyCommand ) ]"
    }
    Write-Host -ForegroundColor Cyan "Current Scope: [ $( $MyInvocation.MyCommand ) ]"
    Get-ScopeName2
}

Get-ScopeName1
