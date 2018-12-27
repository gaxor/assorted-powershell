# Requires external function: Measure-TMCommand
#   Link: https://gallery.technet.microsoft.com/Measure-Command-with-52158178

$FooSwitch = {
    [System.Collections.ArrayList] $NotReally = @()
    Switch( $Host.Name )
    {
        'ConsoleHost'
        {
        1..100 | ForEach { $NotReally.add( $_+9538*214/359 ) }
        }
        'Windows PowerShell ISE Host'
        {
        1..100 | ForEach { $NotReally.add( $_+9538*214/359 ) }
        }
    }
    Clear-Variable NotReally
}

$FooIfElse = {
    [System.Collections.ArrayList] $NotReally = @()
    If ( $Host.Name -eq 'ConsoleHost' )
    {
        1..100 | ForEach { $NotReally.add( $_+9538*214/359 ) }
    }
    Else
    {
        1..100 | ForEach { $NotReally.add( $_+9538*214/359 ) }
    }
    Clear-Variable NotReally
}

$SwitchArray = Measure-TMCommand -Command $FooSwitch -Repetitions 3000 | select -ExpandProperty AverageMilliseconds
$IfElseArray = Measure-TMCommand -Command $FooIfElse -Repetitions 3000 | select -ExpandProperty AverageMilliseconds

$SwResults = $SwitchArray | select -Last 1
$IfResults = $IfElseArray | select -Last 1

"SwResults = $SwResults"
"IfResults = $IfResults"
