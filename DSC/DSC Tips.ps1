<## DSC Tips ##>

# Inject DSC config:
Copy-Item -Path '\\SOURCE\SHARE\metaconfig.mof' -Destination '\\DESTINATION\C$\Windows\System32\Configuration\metaconfig.mof'

# Push DSC config via PS remoting:
Set-DscLocalConfigurationManager -Path ./LCMConfig -ComputerName 'DESTINATION' -verbose

# WMF 4 DSC injection:
# http://dille.name/blog/2014/12/07/injecting-powershell-dsc-meta-and-node-configurations
# https://blogs.msdn.microsoft.com/powershell/2014/02/28/want-to-automatically-configure-your-machines-using-dsc-at-initial-boot-up


<## Common Scenarios ##>

# Get LCM settings
Get-DscLocalConfigurationManager

# Get DSC report
Test-DscConfiguration

# Get DSC config
Get-DscConfiguration

# Set LCM settings
Set-DscLocalConfigurationManager -Path .\LCMConfig -Wait -Force -Verbose

# Set DSC config
Start-DscConfiguration -Path .\WebsiteTest1 -Wait -Force -Verbose

# Set DSC state
Restore-DscConfiguration

# Clear pending state
Remove-DscConfigurationDocument -Stage Pending
# or:
Remove-Item "$env:systemRoot/system32/configuration/pending.mof" -Force; Get-Process *wmi* | Stop-Process -Force; Restart-Service winrm -Force
