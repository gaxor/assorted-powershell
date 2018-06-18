# Requires external function: Measure-TMCommand
#   Link: https://gallery.technet.microsoft.com/Measure-Command-with-52158178

$data = New-Object byte[]( 5000 )

Measure-TMCommand -Command {$data | out-null} -Repetitions 50 | select -Last 1 -ExpandProperty AverageMilliseconds
Measure-TMCommand -Command {[void]$data} -Repetitions 50 | select -Last 1 -ExpandProperty AverageMilliseconds
