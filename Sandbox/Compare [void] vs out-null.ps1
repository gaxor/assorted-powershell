# Requires external function: Measure-TMCommand
#   Link: https://gallery.technet.microsoft.com/Measure-Command-with-52158178

$data = New-Object byte[]( 5000 )

Measure-TMCommand -Command {$data | out-null} -Repetitions 50 | select -Last 1 -ExpandProperty AverageMilliseconds
Measure-TMCommand -Command {[void]$data} -Repetitions 50 | select -Last 1 -ExpandProperty AverageMilliseconds

# More tests with built-in measure-command
Clear-Variable data
Measure-Command {
    $data = New-Object byte[](5000)
    $data | out-null
} | select -expand totalmilliseconds | write-host -fore yel

Clear-Variable data
Measure-Command {
    $data = New-Object byte[](5000)
    [void]$data
} | select -expand totalmilliseconds | write-host -fore yel

Clear-Variable data
Measure-Command {
    $data = New-Object byte[](5000)
    $data = $null
} | select -expand totalmilliseconds | write-host -fore yel

Clear-Variable data
Measure-Command {
    $data = New-Object byte[](5000)
    Clear-Variable data
} | select -expand totalmilliseconds | write-host -fore yel
