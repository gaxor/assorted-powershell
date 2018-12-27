# GUI tool to keep an eye on multiple network connections' up status with ICMP
# By Greg Rowe

#[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

Function Ping-Host
{
    Param( $Destination )
    $packetSize = 5000
    $buffer     = New-Object byte[] ( [System.Math]::Min( 65500, $packetSize ) )
    $timeout    = 1000
    $ping       = New-Object System.Net.NetworkInformation.Ping

    $ping.Send( $Destination, $timeout, $buffer ) | Select Status, Address, RoundtripTime
}

[System.Collections.ArrayList] $DestinationHosts = @(
    #"127.0.0.1"
    #"192.168.88.241"
    ( Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } ).NextHop
    #"192.168.100.1"
    "8.8.8.8"
    #"208.67.222.222"
    #"209.244.0.3"
)


ForEach ( $DestinationHost in $DestinationHosts )
{
    Ping-Host -Destination $DestinationHost
}

# Main window
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Ping Form"

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Host Latency"
$Label.AutoSize = $True

$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000
$Timer.Add_Tick({ $Label })
$Timer.Enabled = $True

$Form.Controls.Add( $Label )
[void] $Form.ShowDialog()