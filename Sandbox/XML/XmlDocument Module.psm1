Function Out-HashTableToXml
{
    # Objective: Export Hashtable to xml in a human readable format
    # Output   : [XmlDocument]
    # Example  : Out-HashTableToXml -InputObject $XmlObject -Root 
    # Notes    : Modified from: https://gallery.technet.microsoft.com/scriptcenter/Export-Hashtable-to-xml-in-122fda31

    [cmdletbinding()]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [Hashtable] $InputObject,
        [ValidateNotNullOrEmpty()]
        [String] $Root
    )
    Begin
    {
        $ScriptBlock =
        {
            Param
            (
                $Elem,
                $Root
            )

            If ($Elem.Value -is [Array])
            {
                $Elem.Value | Foreach-Object {
                    $ScriptBlock.Invoke( @( @{ $Elem.Key=$_ }, $Root ) )
                }
            }

            If( $Elem.Value -is [System.Collections.Hashtable] )
            {
                $RootNode = $Root.AppendChild( $Doc.CreateNode( [System.Xml.XmlNodeType]::Element, $Elem.Key, $Null ) )
                $Elem.Value.GetEnumerator() | ForEach-Object {
                    $Scriptblock.Invoke( @($_, $RootNode) )
                }
            }
            Else
            {
                $Element = $Doc.CreateElement( $Elem.Key )
                $Element.InnerText =
                If ( $Elem.Value -is [Array] )
                {
                    $Elem.Value -join ','
                }
                Else
                {
                    $Elem.Value | Out-String
                }

                $Root.AppendChild( $Element ) | Out-Null	
            }
        }
    }
    Process
    {
        $Doc = [xml]"<$( $Root )></$( $Root )>"
        $InputObject.GetEnumerator() | ForEach-Object {
            $scriptblock.Invoke( @( $_, $doc.DocumentElement ) )
        }
        
        $Doc
    }
}

Function Get-WebConfigRedirectRule
{
    # Objective: Returns redirect rule(s) from specified web.config (XML) file by name (accepts wildcards)
    # Output   : [XmlLinkedNode] if only one match | [Array] if multiple matches
    # Example  : Get-WebConfigRedirectRule -FilePath 'C:\temp\Web.config' -Name 'HTTP*'

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [ValidateScript({ Test-Path $_ -IsValid })]
        [String] $FilePath,
        [String] $Name = '*'
    )

    [xml] $Xml = Get-Content -Path $FilePath -ErrorAction Stop

    $Rules = $Xml.configuration.'system.webServer'.rewrite.rules.rule

    # If there are multiple rules
    If ( $Rules.GetType().BaseType.Name -eq 'Array' )
    {
        If ( $Rules | Where { $_.name -like $Name } )
        {
            Return $Rules | Where { $_.name -like $Name }
        }
    }
    # If there is only one rule
    ElseIf ( $Rules.GetType().BaseType.Name -eq 'XmlLinkedNode' )
    {
        Write-Verbose "There is only one rule"
        If ( $Rules.name -like $Name )
        {
            Return $Rules
        }
    }

    Write-Warning "No rule found with the name `"$Name`""
}

Function Set-WebConfigHttpsRedirect # Not complete ( I think the issue is near line 179)
{
    # Objective: 
    # Output   : 
    # Example  : Set-WebConfigRedirectRule

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [ValidateScript({ Test-Path $_ -IsValid })]
        [String] $FilePath,
        [String] $Name = "HTTP to HTTPS Redirect",
        [Alias( 'Match' )]
        [String] $MatchUrl = '(.*)'
    )
    
    [String[]] $ElementParents = 'configuration','system.webServer','rewrite','rules'
    [xml] $InputElement = @"
        <rule name="$Name" enabled="true" stopProcessing="true">
          <match url="$MatchUrl" />
          <conditions logicalGrouping="MatchAny">
          <add input="{SERVER_PORT_SECURE}" pattern="^0$" />
          </conditions>
          <action type="Redirect" url="https://{HTTP_HOST}{REQUEST_URI}" redirectType="Permanent" />
        </rule>
"@ # Intentionally non-indented

    # Add single quotes to element parents that include a period in the name
    ForEach ( $Parent in $ElementParents )
    {
        If ( $Parent -like '*.*' )
        {
            $Index = [Array]::IndexOf( $ElementParents, $Parent )
            $ElementParents[$Index] = "'$Parent'"
        }
    }

    # Load XML from file
    [xml] $Xml = Get-Content -Path $FilePath
    $ElementLocation = $ElementParents -join '.'

    # Recursively create parent XML elements if not present
    ForEach ( $Parent in $ElementParents )
    {
        $Index         = [Array]::IndexOf( $ElementParents, $Parent )
        $ParentPath    = $ElementParents[0..$Index] -join '.'
        $ParentElement = Invoke-Expression "`$Xml.$ParentPath"

        # If parent element does not exist, create it
        If ( -not $ParentElement )
        {
            # The first item in the list won't have a parent; keep index number
            If ( $Index -eq 0 )
            {
                $GrandparentIndex = 0
            }
            # Get previous item's index number
            Else
            {
                $GrandparentIndex = $Index - 1
            }

            $GrandparentPath = $ElementParents[0..$GrandparentIndex] -join '.'

            # Create parent element
            Invoke-Expression "`$Xml.$GrandparentPath.AppendChild( `$Xml.CreateElement( '$Parent' ) )"
        }
    }

    # Import our InputElement var (as a new [XmlElement]) to the [XmlDocument] scope, then add it to the proper path
    Invoke-Expression "`$Xml.$ElementLocation.AppendChild( `$Xml.ImportNode( $InputElement, $True ) )"

    # Save file
    $Xml.Save( $FilePath )
}

Function Get-WebConfigStrictTransportSecurity # Not complete
{
    [CmdletBinding()]
    Param
    (
        
    )
}

Function Set-WebConfigStrictTransportSecurity # Not complete
{
    [CmdletBinding()]
    Param
    (
        
    )
}


Export-ModuleMember -Function Get-WebConfigRedirectRule #,
                              #Set-WebConfigHttpsRedirect,
                              #Get-WebConfigStrictTransportSecurity,
                              #Set-WebConfigStrictTransportSecurity