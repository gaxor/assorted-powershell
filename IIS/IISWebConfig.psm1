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
                              #Get-WebConfigStrictTransportSecurity,
                              #Set-WebConfigStrictTransportSecurity