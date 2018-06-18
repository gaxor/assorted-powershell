# List installed hotfixes (I've never seen this work entirely well)
Get-WmiObject -Class "win32_quickfixengineering" | Select-Object -Property "Description", "HotfixID", @{Name="InstalledOn"; Expression={([DateTime]($_.InstalledOn)).ToLocalTime()}}

# List installed Microsoft software from registry
Get-ChildItem HKLM:\SOFTWARE\Microsoft\ | select name

# List installed applications
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName
