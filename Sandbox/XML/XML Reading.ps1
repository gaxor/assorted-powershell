# Good XML resource: https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-data-basics-xml/

$FilePath = 'C:\Users\Greg\Documents\GIT\greg-powershell\Sandbox\XML\Cars.xml'

###############################
# Powershell XML Object Types:
<#
    Select-Xml
        returns SelectXmlInfo object

    SelectNodes
        returns XmlNodeList object

    SelectSingleNode
        returns XmlNode object
#>

###############################
# Different XML read techniques:

# Get-Content
[xml] $XmlDocument = Get-Content -Path $FilePath

# Xml Method
$XmlDocument = New-Object System.Xml.XmlDocument
$XmlDocument.load($FilePath)

# Xml from a String
[xml] $Catalog = @"
<?xml version="1.0"?>
<catalog>
   <book id="bk101">
      <author>Gambardella, Matthew</author>
      <title>XML Developer's Guide</title>
      <genre>Computer</genre>
      <price>44.95</price>
      <publish_date>2000-10-01</publish_date>
      <description>An in-depth look at creating applications 
      with XML.</description>
   </book>
</catalog>
"@

###############################
# Navigate XML tree with XPath

# SelectNodes Method
$XmlDocument.SelectNodes("//Seats")
$XmlDocument.SelectSingleNode("//Car[2]")

# Expand the Cars array
$XmlDocument.Cars.GetEnumerator()

###############################
# Accessing XML Objects

[xml] $Books = 'C:\Users\Greg\Documents\GIT\greg-powershell\Sandbox\XML\Books.xml'

# The following three commands return the same result:

# SelectNodes, FirstChild
( $Books.SelectNodes(“//author”) ).GetType() # Object Type: XmlNodeList
  $Books.SelectNodes(“//author”) | % { $_.FirstChild.Value }

# SelectNodes, InnerText
( $Books.SelectNodes(“//author”) ).GetType() # Object Type: XmlNodeList
  $Books.SelectNodes(“//author”) | % { $_.InnerText }

# Select-Xml, expand Node
( $Books | Select-Xml “//author” ).GetType() # Object Type: Array
  $Books | Select-Xml “//author” | % { $_.Node.InnerText }


# more playing around with gathering info from xml:
$Books.SelectSingleNode(“/catalog”)
($Books | Select-Xml “/catalog”).Node
($Books | Select-Xml “/catalog”).Node | ft -AutoSize
$Books.catalog.GetEnumerator() | ft -AutoSize

###############################