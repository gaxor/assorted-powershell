$VmName = 'server1'
Get-VM -Name $VmName | Set-VMFirmware $_ -EnableSecureBoot Off
