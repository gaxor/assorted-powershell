# Exiting loops before they're written to end

$Collection = 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5

ForEach ( $Number in $Collection )
{
    Write-Host -ForegroundColor Cyan "[Start] $number"
    if ( $Number -lt 2 )
    {
        Continue # This will skip the current foreach item
    }
    elseif ( $Number -is [int32] )
    {
        Write-Host `t`t$Number -BackgroundColor Black
        If ( $Number -gt 3 )
        {
            Write-Host `t`t$Number -ForegroundColor Red -BackgroundColor Black
            break # This will immediately end the foreach loop
        }
    }
    elseif ( $Number -is [double] )
    {
        Write-Host `t`t$Number -BackgroundColor Black
    }

    Write-Host -ForegroundColor DarkCyan "[End  ] $number"
}