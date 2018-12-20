#Requires -Module CredentialManager

# By Greg Rowe June 2018
# !! I've gotten a bunch of the API syntaxes wrong, and I still need to comb through and find them all

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Function Get-SamanageHeaders
{
    $Headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
    $Headers.Add( 'X-Samanage-Authorization', "Bearer $( Get-SamanageApiToken )" )
    $Headers.Add( 'Accept', 'application/vnd.samanage.v2.1+json' )
    $Headers
}

Function Get-CommonParameter
{
    # Code from: https://gallery.technet.microsoft.com/scriptcenter/Get-CommonParameter-List-840d72c4
    [cmdletbinding()]
    Param()
    Function _temp { [cmdletbinding()] Param() }
    ((Get-Command _temp).Parameters).Keys
}

Function Set-SamanageApiToken
{
    Param
    (
        [Parameter(Mandatory=$True)]
        $Token
    )

    New-StoredCredential -Target 'Samanage API Token' -UserName 'Samanage API Token' -Password $Token -Type 'Generic' -Persist 'LocalMachine'
}

Function Get-SamanageApiToken
{
    Try
    {
        (Get-StoredCredential -Target 'Samanage API Token' -WarningAction Ignore).GetNetworkCredential().Password
    }
    Catch
    {
        Write-Warning 'Samanage API token not found in Credential Manager. Try importing it with "Set-SamanageApiToken"'
        Break
    }
}

Function Get-SamanageData
{
    Param
    (
        [Parameter(Mandatory=$True)]
        [String] $RequestType,
        [String] $Filter
    )

    $RequestType = $RequestType.ToLower()
    If ( $Filter[0] -ne '?' )
    {
        $Filter = ( "?$Filter" -replace ' ' ).ToLower()
    }
    Else
    {
        $Filter = ( $Filter -replace ' ' ).ToLower()
    }

    $Params = @{
        Uri         = "https://api.samanage.com/$RequestType.json$Filter )"
        Headers     = Get-SamanageHeaders
        ContentType = 'application/json'
        Method      = 'Get'
        ErrorAction = 'SilentlyContinue'
    }

    $Response = Invoke-WebRequest @Params
    $Output   = $Response.Content | ConvertFrom-Json
    
    If ( $Response.Headers.'X-Total-Pages' -gt 1 )
    {
        $PageCount = 2..( [int] $Response.Headers.'X-Total-Pages' )
        ForEach ( $Page in $PageCount )
        {
            $Params.Uri = "https://api.samanage.com/$RequestType.json?per_page=100&page=$Page$Filter )"
            $Output += ( Invoke-WebRequest @Params ).Content  | ConvertFrom-Json
        }
    }

    $Output
}

Function Import-Settings
{
    Param
    (
        $Path = (Join-Path $PSScriptRoot 'Settings.json')
    )

    ( Get-Content -Path $Path -ErrorAction SilentlyContinue ) -join "`n" | ConvertFrom-Json | ConvertTo-Hashtable
}

Function Import-IncidentTemplates
{
    Param
    (
        $Path = (Join-Path $PSScriptRoot 'IncidentTemplates.json')
    )

    ( Get-Content -Path $Path -ErrorAction SilentlyContinue ) -join "`n" | ConvertFrom-Json | ConvertTo-Hashtable
}

Function Save-IncidentTemplates
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        $InputObject,
        $Path = (Join-Path $PSScriptRoot 'IncidentTemplates.json')
    )

    ConvertTo-Json -InputObject $InputObject | Out-File $Path
}

Function New-IncidentTemplate
{
    Param
    (
        [Parameter(Mandatory=$True)]
        $Parameters
    )

    @{
        Name   = Get-NewTemplateName
        Params = $Parameters
    }
}

Function Get-SamanageSettings
{
    @{
        Categories = [Array] ( Get-SamanageData -RequestType 'categories' ).Where{ -not $_.Parent_ID }
        Locations  = Get-SamanageData -RequestType 'sites'
        AllUsers   = Get-SamanageData -RequestType 'users' | Select 'id','name','disabled','created_at','department','title','email','role'
    }
}

Function New-SamanageIncident
{
    Param
    (
        #[Parameter(Mandatory=$True)]
        [Alias('Title')]
        $Name = "Test Ticket $( Get-Date -Format G )",
        [Parameter(Mandatory=$True)]
        $Requestor,
        $Priority = 'Medium',
        $Description,
        $Due_at,
        $Assignee,
        [String[]] $Incidents,
        $Assets,
        [int] $Problem,
        $Solutions,
        $Category,
        $Subcategory,
        $State,
        [Alias('Location')]
        $Site
    )

    $SamanageCategory = 'incidents'

    $Body = @{
        name        = $Name
        requestor   = [String] $Requestor
        priority    = [String] $Priority
        description = [String] $Description
        due_at      = [String] $Due_at
        assignee    = [String] $Assignee
        incidents   = [Array]  $Incidents
        assets      = [Array]  $Assets
        problem     = [int]    $Problem
        category    = @{ name = [String] $Category }
        subcategory = @{ name = [String] $Subcategory }
    }

    $Params = @{
        Uri         = "https://api.samanage.com/$SamanageCategory.json".ToLower()
        Headers     = Get-SamanageHeaders
        ContentType = 'application/json'
        Method      = 'Post'
        Body        = ConvertTo-Json $Body -Compress
    }
    Invoke-RestMethod @Params
}

Function Start-IncidentBuilder
{
    [CmdletBinding()]
    Param
    (
        $Requesters,
        $Assignees,
        $Priorities,
        $Categories,
        $Statuses
    )

    $Font     = 'Microsoft Sans Serif,10'
    $BoxWidth = 180

    $MainForm                        = New-Object system.Windows.Forms.Form
    $MainForm.ClientSize             = '380,400'
    $MainForm.text                   = "New Incident"
    $MainForm.TopMost                = $false
    $MainForm.Icon                   = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + '\powershell.exe')

    $Title_Label                     = New-Object system.Windows.Forms.Label
    $Title_Label.text                = "Title"
    $Title_Label.AutoSize            = $true
    $Title_Label.width               = 25
    $Title_Label.height              = 10
    $Title_Label.location            = New-Object System.Drawing.Point(10,10)
    $Title_Label.Font                = $Font

    $Title_Box                       = New-Object system.Windows.Forms.TextBox
    $Title_Box.multiline             = $false
    $Title_Box.width                 = 270
    $Title_Box.height                = 20
    $Title_Box.Anchor                = 'top,right,left'
    $Title_Box.location              = New-Object System.Drawing.Point(100,10)
    $Title_Box.Font                  = $Font

    $Requestor_Label                 = New-Object system.Windows.Forms.Label
    $Requestor_Label.text            = "Requester"
    $Requestor_Label.AutoSize        = $true
    $Requestor_Label.width           = 25
    $Requestor_Label.height          = 10
    $Requestor_Label.location        = New-Object System.Drawing.Point(10,40)
    $Requestor_Label.Font            = $Font

    $Requestor_Box                   = New-Object system.Windows.Forms.ComboBox
    $Requestor_Box.width             = $BoxWidth
    $Requestor_Box.height            = 20
    $Requestor_Box.location          = New-Object System.Drawing.Point(100,40)
    $Requestor_Box.Font              = $Font

    $Priority_Label                  = New-Object system.Windows.Forms.Label
    $Priority_Label.text             = "Priority"
    $Priority_Label.AutoSize         = $true
    $Priority_Label.width            = 25
    $Priority_Label.height           = 10
    $Priority_Label.location         = New-Object System.Drawing.Point(10,70)
    $Priority_Label.Font             = $Font

    $Priority_Box                    = New-Object system.Windows.Forms.ComboBox
    $Priority_Box.width              = $BoxWidth
    $Priority_Box.height             = 20
    $Priority_Box.location           = New-Object System.Drawing.Point(100,70)
    $Priority_Box.Font               = $Font

    $Assignee_Label                  = New-Object system.Windows.Forms.Label
    $Assignee_Label.text             = "Assignee"
    $Assignee_Label.AutoSize         = $true
    $Assignee_Label.width            = 25
    $Assignee_Label.height           = 10
    $Assignee_Label.location         = New-Object System.Drawing.Point(9,100)
    $Assignee_Label.Font             = $Font

    $Assignee_Box                    = New-Object system.Windows.Forms.ComboBox
    $Assignee_Box.text               = ( [ADSI]"WinNT://$env:USERDOMAIN/$env:USERNAME,user" ).FullName
    $Assignee_Box.width              = $BoxWidth
    $Assignee_Box.height             = 20
    $Assignee_Box.location           = New-Object System.Drawing.Point(100,100)
    $Assignee_Box.Font               = $Font

    $Category_Label                  = New-Object system.Windows.Forms.Label
    $Category_Label.text             = "Category"
    $Category_Label.AutoSize         = $true
    $Category_Label.width            = 25
    $Category_Label.height           = 10
    $Category_Label.location         = New-Object System.Drawing.Point(10,130)
    $Category_Label.Font             = $Font

    $Category_Box                    = New-Object system.Windows.Forms.ComboBox
    $Category_Box.width              = $BoxWidth
    $Category_Box.height             = 20
    $Category_Box.location           = New-Object System.Drawing.Point(100,130)
    $Category_Box.Font               = $Font

    $Subcategory_Label               = New-Object system.Windows.Forms.Label
    $Subcategory_Label.text          = "Subcategory"
    $Subcategory_Label.AutoSize      = $true
    $Subcategory_Label.width         = 25
    $Subcategory_Label.height        = 10
    $Subcategory_Label.location      = New-Object System.Drawing.Point(10,160)
    $Subcategory_Label.Font          = $Font

    $Subcategory_Box                 = New-Object system.Windows.Forms.ComboBox
    $Subcategory_Box.width           = $BoxWidth
    $Subcategory_Box.height          = 20
    $Subcategory_Box.location        = New-Object System.Drawing.Point(101,160)
    $Subcategory_Box.Font            = $Font

    $Status_Label                    = New-Object system.Windows.Forms.Label
    $Status_Label.text               = "Ticket Status"
    $Status_Label.AutoSize           = $true
    $Status_Label.width              = 25
    $Status_Label.height             = 10
    $Status_Label.location           = New-Object System.Drawing.Point(10,190)
    $Status_Label.Font               = $Font

    $Status_Box                      = New-Object system.Windows.Forms.ComboBox
    $Status_Box.width                = $BoxWidth
    $Status_Box.height               = 20
    $Status_Box.location             = New-Object System.Drawing.Point(100,190)
    $Status_Box.Font                 = $Font

    $Description_Label               = New-Object system.Windows.Forms.Label
    $Description_Label.text          = "Description"
    $Description_Label.AutoSize      = $true
    $Description_Label.width         = 25
    $Description_Label.height        = 10
    $Description_Label.location      = New-Object System.Drawing.Point(10,220)
    $Description_Label.Font          = $Font

    $Description_Box                 = New-Object system.Windows.Forms.TextBox
    $Description_Box.multiline       = $true
    $Description_Box.width           = 360
    $Description_Box.height          = 100
    $Description_Box.Anchor          = 'top,right,bottom,left'
    $Description_Box.location        = New-Object System.Drawing.Point(10,240)
    $Description_Box.Font            = $Font

    $CreateTicket_Button             = New-Object system.Windows.Forms.Button
    $CreateTicket_Button.BackColor   = "#b8e986"
    $CreateTicket_Button.text        = "Create Ticket"
    $CreateTicket_Button.width       = 120
    $CreateTicket_Button.height      = 30
    $CreateTicket_Button.Anchor      = 'bottom,left'
    $CreateTicket_Button.location    = New-Object System.Drawing.Point(10,360)
    $CreateTicket_Button.Font        = $Font

    $SaveTemplate_Button             = New-Object system.Windows.Forms.Button
    $SaveTemplate_Button.BackColor   = "#50e3c2"
    $SaveTemplate_Button.text        = "Save As Template"
    $SaveTemplate_Button.width       = 160
    $SaveTemplate_Button.height      = 30
    $SaveTemplate_Button.Anchor      = 'bottom,left'
    $SaveTemplate_Button.location    = New-Object System.Drawing.Point(($CreateTicket_Button.location.X+$CreateTicket_Button.Width+10),360)
    $SaveTemplate_Button.Font        = 'Microsoft Sans Serif,10'

    $Close_Button                    = New-Object system.Windows.Forms.Button
    $Close_Button.BackColor          = "#a7a7a7"
    $Close_Button.text               = "Close"
    $Close_Button.width              = 60
    $Close_Button.height             = 30
    $Close_Button.Anchor             = 'bottom,right'
    $Close_Button.location           = New-Object System.Drawing.Point(($MainForm.Width-$Close_Button.Width-25),360)
    $Close_Button.Font               = $Font

    # Add functionality to form items
    $Requestor_Box.Items.AddRange( $Requesters )
    $Requestor_Box.AutoCompleteMode   = 'SuggestAppend'
    $Requestor_Box.AutoCompleteSource = 'CustomSource'
    $Requestor_Box.AutoCompleteCustomSource.AddRange( $Requestor_Box.Items )

    $Priority_Box.Items.AddRange( $Priorities )
    $Priority_Box.AutoCompleteMode   = 'SuggestAppend'
    $Priority_Box.AutoCompleteSource = 'CustomSource'
    $Priority_Box.AutoCompleteCustomSource.AddRange( $Priority_Box.Items )
    $Priority_Box.Text               = 'Medium'

    $Assignee_Box.Items.AddRange( $Assignees )
    $Assignee_Box.AutoCompleteMode   = 'SuggestAppend'
    $Assignee_Box.AutoCompleteSource = 'CustomSource'
    $Assignee_Box.AutoCompleteCustomSource.AddRange( $Assignee_Box.Items )

    $Category_Box.Items.AddRange( $Categories.Name )
    $Category_Box.AutoCompleteMode   = 'SuggestAppend'
    $Category_Box.AutoCompleteSource = 'CustomSource'
    $Category_Box.AutoCompleteCustomSource.AddRange( $Category_Box.Items )

    #$Subcategory_Box.Items.AddRange( $Categories.Children.Name )
    $Subcategory_Box.AutoCompleteMode   = 'SuggestAppend'
    $Subcategory_Box.AutoCompleteSource = 'CustomSource'
    $Subcategory_Box.AutoCompleteCustomSource.AddRange( $Subcategory_Box.Items )

    $Status_Box.Items.AddRange( $Statuses )
    $Status_Box.AutoCompleteMode   = 'SuggestAppend'
    $Status_Box.AutoCompleteSource = 'CustomSource'
    $Status_Box.AutoCompleteCustomSource.AddRange( $Status_Box.Items )

    $Category_Box.add_SelectedIndexChanged({
        $Subcategory_Box.Text = ''
        $Subcategory_Box.Items.Clear()
        $Subcategory_Box.AutoCompleteCustomSource.Clear()
        Switch ( $Categories.Where{ $_.Name -eq $Category_Box.Text }.Children.Name.Count )
        {
            0 {}
            1
            {
                $Subcategory_Box.Items.Add(( $Categories.Where{ $_.Name -eq $Category_Box.Text }.Children.Name ))
                $Subcategory_Box.AutoCompleteCustomSource.AddRange( $Subcategory_Box.Items )
            }
            Default
            {
                $Subcategory_Box.Items.AddRange(( $Categories.Where{ $_.Name -eq $Category_Box.Text }.Children.Name ))
                $Subcategory_Box.AutoCompleteCustomSource.AddRange( $Subcategory_Box.Items )
            }
        }
    })

    $CreateTicket_Button.Add_Click({
        If ( -not $Title_Box.text )
        {
            If ( $Subcategory_Box.Text )
            {
                $Title_Box.text = $Requestor_Box.Text + ' - ' + $Subcategory_Box.Text
            }
            Elseif ( $Category_Box.Text )
            {
                $Title_Box.text = $Requestor_Box.Text + ' - ' + $Category_Box.Text
            }
        }
        $NewIncidentParams = @{
            Name        = $Title_Box.Text
            Requestor   = $Requestor_Box.Text
            Priority    = $Priority_Box.Text
            Description = $Description_Box.Text
            Assignee    = $Assignee_Box.Text
            Category    = $Category_Box.Text
            Subcategory = $Subcategory_Box.Text
            State       = $Status_Box.Text
        }

        New-SamanageIncident @NewIncidentParams
    })

    $SaveTemplate_Button.Add_Click({
        $Script:Templates | Add-Member New-IncidentTemplate
    })

    $Close_Button.Add_Click({ $MainForm.Close() })

    $MainForm.controls.AddRange(@(
        $Title_Label
        $Title_Box
        $Requestor_Label
        $Requestor_Box
        $Priority_Label
        $Priority_Box
        $Assignee_Label
        $Assignee_Box
        $Category_Label
        $Category_Box
        $Subcategory_Label
        $Subcategory_Box
        $Status_Label
        $Status_Box
        $Description_Label
        $Description_Box
        $CreateTicket_Button
        $SaveTemplate_Button
        $Close_Button
    ))

    [System.Windows.Forms.Application]::Run( $MainForm )
}

Function Get-NewTemplateName
{
    $New_Template_Form               = New-Object system.Windows.Forms.Form
    $New_Template_Form.ClientSize    = '380,106'
    $New_Template_Form.text          = "New Template"
    $New_Template_Form.TopMost       = $false
    $New_Template_Form.StartPosition = 'CenterParent'
    $New_Template_Form.Icon          = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + '\powershell.exe')
    $New_Template_Form.TopMost       = $true

    $TemplateName_Label              = New-Object system.Windows.Forms.Label
    $TemplateName_Label.text         = "New template name:"
    $TemplateName_Label.AutoSize     = $true
    $TemplateName_Label.width        = 25
    $TemplateName_Label.height       = 10
    $TemplateName_Label.location     = New-Object System.Drawing.Point(20,20)
    $TemplateName_Label.Font         = 'Microsoft Sans Serif,10'

    $TemplateName_Box                = New-Object system.Windows.Forms.TextBox
    #$TemplateName_Box.Text           = "Template ($( $Script:Templates.Count + 1 ))"
    $TemplateName_Box.multiline      = $false
    $TemplateName_Box.width          = 200
    $TemplateName_Box.height         = 20
    $TemplateName_Box.location       = New-Object System.Drawing.Point(160,20)
    $TemplateName_Box.Font           = 'Microsoft Sans Serif,10'

    $OK_Button                       = New-Object system.Windows.Forms.Button
    $OK_Button.text                  = "OK"
    $OK_Button.width                 = 60
    $OK_Button.height                = 30
    $OK_Button.location              = New-Object System.Drawing.Point(160,65)
    $OK_Button.Font                  = 'Microsoft Sans Serif,10'

    $Cancel_Button                   = New-Object system.Windows.Forms.Button
    $Cancel_Button.text              = "Cancel"
    $Cancel_Button.width             = 60
    $Cancel_Button.height            = 30
    $Cancel_Button.location          = New-Object System.Drawing.Point(301,65)
    $Cancel_Button.Font              = 'Microsoft Sans Serif,10'

    $RedText_Label                   = New-Object system.Windows.Forms.Label
    $RedText_Label.AutoSize          = $true
    $RedText_Label.width             = 25
    $RedText_Label.height            = 10
    $RedText_Label.location          = New-Object System.Drawing.Point(167,44)
    $RedText_Label.Font              = 'Microsoft Sans Serif,10'
    $RedText_Label.ForeColor         = "#d0021b"
    $RedText_Label.Visible           = $false

    $New_Template_Form.controls.AddRange(@(
        $TemplateName_Label
        $TemplateName_Box
        $RedText_Label
        $OK_Button
        $Cancel_Button
    ))

    $OK_Button.Add_Click({
        If ( $TemplateName_Box.text -and $TemplateName_Box.text -in $Script:Templates.Name )
        {
            $RedText_Label.text = "*$( $TemplateName_Box.text ) is already a template!"
            $RedText_Label.Visible = $true
        }
        ElseIf ( $TemplateName_Box.Text )
        {
            $Script:New_Template_Form_Text = $TemplateName_Box.Text
            $New_Template_Form.Close()
        }
        Else
        {
            $RedText_Label.text    = "*Name is required"
            $RedText_Label.Visible = $true
            $TemplateName_Box.Focus()
        }
    })
    $Cancel_Button.Add_Click({ $New_Template_Form.Close() })

    [System.Windows.Forms.Application]::Run( $New_Template_Form )

    $Script:New_Template_Form_Text
    Clear-Variable -Name New_Template_Form_Text -Scope Script
}

Function ConvertTo-Hashtable
{
    # function from https://4sysops.com/archives/convert-json-to-a-powershell-hash-table
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

If ( -not ( $Settings = Import-Settings -Path 'C:\Users\growe\documents\git\scripts\Settings.json' ) )
{
    $Settings = Get-SamanageSettings
    $SettingsUpdated = $True
}

If ( -not ( $Templates = Import-IncidentTemplates -Path 'C:\Users\growe\documents\git\scripts\IncidentTemplates.json' ) )
{
    $Templates = New-Object System.Collections.Hashtable
}


#Import-IncidentTemplates
#$IncidentTemplates
$IncidentBuilderParams = @{
    Requesters = $Settings.AllUsers.Name
    Assignees  = $Settings.AllUsers.Where{ $_.Role.Name -ne 'Requester' -and $_.Department.Name -eq 'Information Technology' }.Name
    Priorities = 'None','Low','Medium','High','Critical'
    Categories = $Settings.Categories
    Statuses   = 'New','Assigned','Awaiting Input','On hold','Resolved'
}
Start-IncidentBuilder @IncidentBuilderParams

If ( $Templates.Count -gt 0 )
{
    Save-IncidentTemplates -InputObject $Templates
}

If ( $SettingsUpdated )
{
    ConvertTo-Json -InputObject $Settings -Depth 4 | Out-File 'C:\Users\growe\documents\git\scripts\Settings.json'
}



# ---------------------------
# ---------- Tests ----------
# ---------------------------

#New-SamanageIncident -Name "TestTicket" -Requestor 'user1@domain.com'

<# ---------- First ticket-creation success ----------

    $ApiCategory = 'incidents' # incidents, users, categories
    #$Name        = "Test Ticket $( Get-Date -Format G )"
    $Name        = "Test Ticket $( Get-Date -Format G )"
    $Requestor   = 'user1@domain.com'
    $Assignee    = 'user1@domain.com'
    $Priority    = 'Medium'
    $Description = 'Test - Words go here.'

    $ApiRoot     = 'https://api.samanage.com'
    $Headers     = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
    $Headers.Add( 'X-Samanage-Authorization', "Bearer $( Get-SamanageApiToken )" )
    $Headers.Add( 'Accept', 'application/vnd.samanage.v2.1+json' )
    $ContentType = 'application/json'
    #$Headers.Add( 'Accept', 'application/vnd.samanage.v2.1+xml' )
    #$ContentType = 'text/xml'
    $BodyClass   = $ContentType.Split('/')[1]
    $Uri         = "$ApiRoot/$ApiCategory.$BodyClass".ToLower()

    $Body = @{
        name        = "Test Ticket $( Get-Date -Format G )"
        requestor   = $Requestor
        priority    = $Priority
        description = $Description
        #due_at      = 
        assignee    = $Assignee
        #incidents   =
        #assets      =
        #problem     =
        category     = @{ name   = 'Access' }
        subcategory  = @{ name   = 'Password Reset' }
    }

    $Params = @{
        Uri         = $Uri -replace '(?<!:)\/\/','/'
        Headers     = $Headers
        ContentType = $ContentType
        Method      = 'Post'
        Body        = Switch ( $BodyClass )
        {
            JSON { ConvertTo-Json $Body -Compress }
            XML  { ConvertTo-Xml $Body -As String }
        }
    }

    $Response = Invoke-RestMethod @Params
#>

<# ---------- Create Ticket ----------

$TestBodyInfo = @{
    name      = "Test Ticket $( Get-Date -Format G )"
    requestor = 'user1@domain.com'
    priority  = 'Medium'
}
$TestBody = Switch ( $BodyClass )
{
    JSON { ConvertTo-Json $TestBodyInfo -Compress }
    XML  { ConvertTo-Xml $TestBodyInfo -As String }
}
$TestParams = @{
    Uri         = $Uri
    Headers     = $Headers
    ContentType = $ContentType
    Method      = 'Post'
    Body        = $TestBody
}
Invoke-RestMethod -Uri $Uri -Headers $Headers -ContentType $ContentType -Method Post -Body $TestBody
#Invoke-WebRequest -Uri $Uri -Headers $Headers -ContentType $ContentType -Method Post -Body $TestBody
#>

<# ---------- Get Ticket ----------

$GetParams = @{
    Uri         = "$ApiRoot/$ApiCategory/$( $Response.ID ).$BodyClass".ToLower()
    Headers     = $Headers
    ContentType = $ContentType
    Method      = 'Get'
    ErrorAction = 'SilentlyContinue'
}
$GetResponse = Invoke-RestMethod @GetParams
#>

<# ---------- Delete Ticket ----------

$DeleteParams = @{
    Uri         = "$ApiRoot/$ApiCategory/$( $Response.ID ).$BodyClass".ToLower()
    Headers     = $Headers
    ContentType = $ContentType
    Method      = 'Delete'
    ErrorAction = 'SilentlyContinue'
}
$DeleteResponse = Invoke-RestMethod @DeleteParams
#>

<# ---------- New-SamanageIncident tests ----------

    $a = New-SamanageIncident -Title (get-date -Format G) -Requestor 'user1@domain.com'
    $SkipParams = @(
        'Verbose'
        'Debug'
        'ErrorAction'
        'WarningAction'
        'InformationAction'
        'ErrorVariable'
        'WarningVariable'
        'InformationVariable'
        'OutVariable'
        'OutBuffer'
        'PipelineVariable'
    )
    $Body = New-Object System.Collections.ArrayList
    ForEach ( $ParamName in $a.Values.Where({ $_.Name -notin $SkipParams }).Name )
    {
        $FieldValue = Invoke-Expression "`$$ParamName"
        If ( -not $FieldValue ) { Continue }
        Switch ( $ParamName )
        {
            category    { [void] $Body.Add( @{ 'category'   = @{ name = $FieldValue } } ) }
            subcategory { [void] $Body.Add( @{ 'subcategory'= @{ name = $FieldValue } } ) }
            Default     { [void] $Body.Add( @{ $ParamName   = $FieldValue } ) }
        }
    }
#>

<# ---------- Idea for updating enums, if they're stored in the settings file ----------

    $SettingsText = [IO.File]::ReadAllText(( Resolve-Path $Path ))
    $AllEnumText  = ($SettingsText | Select-String -Pattern '(?smi)(?<=Enum )[^\}]*(?=\})' -AllMatches).Matches.Value
    $Enums        = New-Object PSCustomObject
    ForEach ( $EnumText in $AllEnumText )
    {
        $Sections = $EnumText.Split('{')
        $Enums.Add(@{ $Sections[0] = ( $Sections[1] -Split('\s') ).Where{![String]::IsNullOrEmpty($_)} })
        #$Enums.$($Sections[0]) = ($Sections[1] -Split('\s')).Where{![String]::IsNullOrEmpty($_)}
        #$EnumText | ForEach {@{ ($_.Split('}'))[0] = ($_.Split('}'))[0] }}
    }
#>
