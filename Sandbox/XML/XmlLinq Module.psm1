# Not complete
# I don't remember where the issue was, but I was unable to complete the objective with Linq (I switched to XPath and got it working)

Function Get-AllXNames
{
    # Objective: Return all XNames recursively from an XML Object
    # Output   : [System.Xml.Linq.XName]
    # Example  : Get-AllXNames -XObject [System.Xml.Linq.XElement]::new( '<Root><Element /></Root>' )

    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipeline = $True )]
        $XObject
    )

    Begin
    {
        Add-Type -AssemblyName System.Xml.Linq
    }
    Process
    {
        ForEach($X in $XObject)
        {
            If ($X.Name -is [System.Xml.Linq.XName])
            {
                $X.Name
                $X.Nodes() | Get-AllXNames
            }
            ElseIf($X -is [System.Xml.Linq.XName])
            {
                $X.LocalName
            }
        }
    }
    End{}
}

Function ConvertTo-XmlLinq
{
    Param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipeline = $True )]
        [String] $Element
    )
    Begin
    {
        Add-Type -AssemblyName System.Xml.Linq
    }
    Process
    {
        Try
        {
            [System.Xml.Linq.XElement]::Parse( $Element )
        }
        Catch
        {
            [System.Xml.Linq.XElement]::new( '<Root>' + $Element + '</Root>' )
        }
    }
    End{}
}

Function Set-XmlNodePath
{
    # Objective: Recursively create parent XML elements if not present
    # Output   : 
    # Example  : Set-XmlNodePath
    
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True )]
        [System.Xml.Linq.XElement] $XElement,
        
        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True )]
        [System.Xml.Linq.XDocument] $XDocument
    )

    Begin
    {
        write-host ''
        write-host -fore DarkCyan "Begin with [$($XElement.Name)]"
        Add-Type -AssemblyName System.Xml.Linq
    }
    Process
    {
        ForEach ( $Fragment in [Array]$XElement.Elements() )
        {
            If ( $XDocument.Elements( $Fragment.Name.ToString() ) )
            {
                write-host -fore DarkMagenta $( $XDocument.Elements( $Fragment.Name.ToString() ) )
                write-host -fore DarkYellow "[$( $Fragment.Parent.Name.ToString() )] already has [$( $Fragment.Name.ToString() )]"
            }
            Else
            {
                write-host -fore Green "[$( $Fragment.Parent.Name.ToString() )] creating [$( $Fragment.Name.ToString() )]"
                $XDocument.Descendants( $Fragment.Parent.Name.ToString() ).Add( $Fragment.Name.ToString() )
                write-host -fore DarkMagenta $( $XDocument.Elements( $Fragment.Name.ToString() ) )
            }

            If ( $Fragment.HasElements )
            {
                write-host -fore cyan "[$($Fragment.name.ToString())] has elements"
                Set-XmlNodePath -XElement $Fragment -XDocument $XDocument
            }
        }
    }
    End{}
}

Add-Type -AssemblyName System.Xml.Linq
$Value = '0000'
$Element = @"
<Root>
    <Three>
        <Three.One>
            <Three.One.Two   id="3.1.2" value="$Value" />
            <Three.One.Three id="3.1.3" value="$Value" />
        </Three.One>
    </Three>
</Root>
"@
$ScenarioDoc1 = @"
<Root>
    <One id="1" />
    <Two id="2" />
</Root>
"@
$ScenarioDoc2 = @"
<Root>
    <One id="1" />
    <Two id="2" />
    <Three>
        <Three.One>
            <Three.One.One id="3.1.1" />
        </Three.One>
    </Three>
</Root>
"@

# Scenario 1:
$Xml = [System.Xml.Linq.XDocument]::Parse($ScenarioDoc1)
Set-XmlNodePath -XElement ($Element | ConvertTo-XmlLinq) -XDocument $Xml
$xml.Save('c:\temp\web.config1')

# Scenario 2:
$Xml = [System.Xml.Linq.XDocument]::Parse($ScenarioDoc2)
Set-XmlNodePath -XElement ($Element | ConvertTo-XmlLinq) -XDocument $Xml
$xml.Save('c:\temp\web.config2')

<# Inside-the-function variable testing
$XElement = $Element | ConvertTo-XmlLinq
$XDocument = $Xml
$Fragment = ( [array]$XElement.Elements() )[0]
#>

Function Add-XmlElement
{
    # Objective: Add XML element to an XML file
    # Output   : XML-styled string
    # Example  : Add-XmlElement

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [ValidateScript({ Test-Path $_ -IsValid })]
        [String] $FilePath,
        
        [Parameter(Mandatory=$True)]
        [String] $Element,
        
        [Parameter(Mandatory=$True)]
        [String[]] $ElementParents,
        
        [String] $OutputFilePath,

        [Switch] $DisallowDuplicateNodes
    )

    Add-Type -AssemblyName System.Xml.Linq

    # Convert full element to XML
    $InputElement = [System.Xml.Linq.XElement]::new( '<Root>' + $Element + '</Root>' )

    # Load XML from file
    $Xml = [System.Xml.Linq.XDocument]::Load( $FilePath )

    # Recursively create parent XML elements if not present
    foreach ($Parent in $ElementParents)
    {
        $Index = [Array]::IndexOf( $ElementParents, $Parent )
        
        # If parent element does not exist, create it
        if ( -not $Xml.Descendants( $Parent ).Name )
        {
            # The first item in the list won't have a parent; keep index
            If ( $Index -eq 0 )
            {
                $Grandparent = $ElementParents[0]
            }
            # Get previous item's index number
            Else
            {
                $Grandparent = $ElementParents[$Index - 1]
            }
            
            # Create parent element
            $Xml.Descendants( $Grandparent ).Add( [System.Xml.Linq.XElement]::new( [System.Xml.Linq.XName] $Parent ) )
        }
    }

    # Add element(s) to destination path
    # $InputElement.Elements() isn't enumerating properly!
    ForEach ( $Fragment in $InputElement.Elements() )
    {
        If ( $DisallowDuplicateNodes -eq $True )
        {
            #$Fragment | ForEach-Object { $Xml.Descendants( $Fragment ).Name }
            #$Xml.Descendants( $ElementParents[-1] ).ReplaceAttributes( $Fragment )
            #$Fragment.Attribute('name') | ForEach-Object { $Xml.Descendants( $Fragment ) }
            $Xml.Descendants( $Fragment.Name ).ReplaceAttributes( $Fragment )
        }
        Else
        {
            $Xml.Descendants( $ElementParents[-1] ).Add( $Fragment )
        }
    }

    # Save to file
    If ( !$OutputFilePath )
    {
        $OutputFilePath = $FilePath
    }
    $Xml.Save( $OutputFilePath )
}

Export-ModuleMember -Function Add-XmlElement