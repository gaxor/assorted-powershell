@Echo Off
SET filePath="%~dp0\Scripts\Controller.ps1"
SET psCommand="&{ Start-Process -FilePath Powershell.exe -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Unrestricted -File %filePath%' -Verb RunAs }"
Powershell.exe -NoProfile -ExecutionPolicy Unrestricted -WindowStyle Hidden -Command %psCommand%
Exit