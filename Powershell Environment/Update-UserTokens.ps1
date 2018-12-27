# Refresh user/group tokens without logging out
$Credential = Get-Credential -UserName $env:USERNAME -Message "User authentication required"

Stop-Process -Name explorer -Force
Start-Process -FilePath explorer.exe -Credential $Credential