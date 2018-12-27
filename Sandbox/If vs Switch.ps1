$n = 5

# Only the first true expression will run its scriptblock
If ( $n -eq 5 )
{
    write-host -fore green "$n -eq 5"
}
ElseIf ( $n -lt 10 )
{
    write-host -fore green "$n -lt 10"
}
Else
{
    Write-Host -fore Red "caught"
}

# Every true expression will run its scriptblock
Switch ($n)
{
    ( 5 )   {write-host -fore green "$_ -eq 5"}
    ( 2+3 ) {write-host -fore green "$_ -lt 10"}
    Default {Write-Host -fore Red "caught"}
}