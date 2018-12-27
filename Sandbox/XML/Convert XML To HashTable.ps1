$File  = "$HOME\Desktop\web.config"

# Connection strings
$XPath = '//connectionStrings/add'
$Name  = 'core'
$XML     = Select-Xml -Path $File -XPath $XPath
$XmlObj  = $XML.Node.Where({ $_.name -eq $Name }).connectionString -split ';'

# Session state section
$XPath = '//configuration/system.web/sessionState'
$XML     = Select-Xml -Path $File -XPath $XPath
$XmlObj  = $XML.Node
$XmlHash = $XmlObj | ConvertFrom-StringData
