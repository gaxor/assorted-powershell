
function foo
{
    [CmdletBinding()]
    param()
    write-host -fore green "foo: $verbosepreference"
    write-verbose 'foo!'

    function bar
    {
        [CmdletBinding()]
        param()
        write-host -fore green "bar: $verbosepreference"
        write-verbose 'bar!'
    }
    bar
}

foo

foo -verbose
