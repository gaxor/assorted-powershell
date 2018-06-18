# Does not work

$Path = 'C:\Users\Greg\Downloads\Nifty-Things Emails\Mail\test.mbox'

Function Get-MboxSectionType
{
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        [String[]] $Text
    )

    Begin
    {
        $Sections = [Array] $global:MessagePartsRegex.Keys
        $Output = New-Object System.Collections.ArrayList
    }
    Process
    {
        $Sections | ForEach { If ( $global:MessagePartsRegex.$_.Match( $Text ).Success ) { $_ } }
    }
    End {}
}

$MessagePartsRegex = @{
    GmailLabels  = [RegEx] '^X-Gmail-Labels: '
    Date         = [RegEx] '^Date: '
    DeliveredTo  = [RegEx] '^Delivered-To: '
    MessageID    = [RegEx] '^Message-ID: '
    Subject      = [RegEx] '^Subject: '
    Sender       = [RegEx] '^From: '
    Recipients   = [RegEx] '^To: '
    ContentType  = [RegEx] '^Content-Type: '
    #Body         = [RegEx] ''
    #Boundary     = [RegEx] ' boundary='
    MessageEnd   = [RegEx] '(--[a-z0-9]{28}--)'
    EmptyLine    = [RegEx] '^\s*$'
}

$MboxData = (Get-Content $Path -Raw) -split ($MessagePartsRegex.MessageEnd)
$Mail = New-Object System.Collections.ArrayList

ForEach ( $Mbox in $MboxData )
{
    ForEach ( $Line in $Mbox.Where({ -not [String]::IsNullOrEmpty($_) }) )
    {
        $Section = Get-MboxSectionType -Text $Line
        If ( $Section -eq 'MessageEnd' )
        {
            [void] $Mail.Add( $Message )
            Clear-Variable Message
            Continue
        }

        Try
        {
            [void] $Message.GetType().FullName
        }
        Catch
        {
            $Message = New-Object System.Collections.Hashtable
        }

        Try
        {
            $PartNameRegex = [RegEx] ( '(?>' + $MessagePartsRegex.$Section.ToString().SubString(1) + ')(.*)' )
            $Message.$Section = $PartNameRegex.Match( $Line ).Groups[1].Value
            write-host -fore green "section: $Section - $($Message.$Section)"
        }
        Catch
        {
            write-host -fore Yellow "section: $Section"
        }
    }
}

#$Line = $MboxData[6]
#$Text = $MboxData[6]