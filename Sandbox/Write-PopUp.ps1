# Script to show message as a wscript popup
# Written by Greg Rowe (Feb 2017)
# Popup options help: https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx

Param
(
    [Parameter(Mandatory=$True)]
    $Message,
    $Title,
    [ValidateCount(0,6)]
    [Int]$Buttons = 0,
    [ValidateSet(0,16,31,48,64)]
    [Int]$Icon    = 0
)

( New-Object -ComObject Wscript.Shell ).Popup( $Message ,$Icon, $Title, $Buttons )
Write-Output $LASTEXITCODE