Function Get-NestedProperty ( $Object, $Value )
{
    ForEach ( $Nested in $Value.split( '.' ) )
    {
        $Object = Invoke-Expression "`$Object.$Nested"
    }

    Return $Object
}
