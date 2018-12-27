# This does not work yet
# original idea from: https://stackoverflow.com/questions/3202567/how-can-i-update-the-value-for-a-xml-node-using-powershell


$Xml = [Xml] ( Get-Content $File )
$XPath = '//sitecore'
$Subject = @{ 'sc.variable' = 'dataFolder' }
$Desired = @{ 'value' = 'GAXOR' }
$Data = Select-Xml -Xml $Xml -XPath $XPath
( $Data.Node[$Subject.Keys] | Where-Object { $_.name -eq $Subject.Values } ).Values = $Desired.Keys


#$x.Save($File)