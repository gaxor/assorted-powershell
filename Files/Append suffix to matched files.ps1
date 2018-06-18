$Path = "c:\temp\forbidden"
$Suffix = ".disabled"
$FileNames = @()

$AllFiles = Get-ChildItem -File -Path $Path
$FilesToUpdate = $AllFiles | Where { $_.Name -in $FileNames }
$FilesToUpdate | ForEach { Rename-Item -Path $_.FullName -NewName "$($_.Name)$Suffix" }
