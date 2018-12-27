############################
# Quick method, but ultimately doesn't work due to $FileWrite.Close() currently erasing the file
# Idea from https://stackoverflow.com/questions/34853307/use-streamwriter-to-write-to-the-same-file-as-streamreader

$FilePath = 'C:\temp\sitecore.config'

# Replace whatever regex finds with the following
$ReplaceWith = 'GAXOR'

# Text before capture group
# Be sure to escape double-quotes with a backslash for the regex engine
$LookBehind = 'sc.variable name=\"dataFolder\" value=\"'

# Text after capture group
$LookAhead = '\"'

[RegEx] $Pattern = "(?<=$LookBehind).*(?=$LookAhead)"
$FileRead = New-Object System.IO.StreamReader -ArgumentList $FilePath
$i = 0
While ( $Line = $FileRead.ReadLine() )
{
    $i++
    If ( [RegEx]::Match( $Line, $Pattern ).Success )
    {
        $NewLine = $Line -replace $Pattern, $ReplaceWith
        $FileWrite = New-Object System.IO.StreamWriter -ArgumentList $FilePath
        $FileWrite.WriteLine( $NewLine )
        $FileWrite.Close()
        Break
    }
    write-host -fore cyan $i
}
$FileRead.Close()


############################
# Slower but simpler method:

$FilePath    = 'C:\temp\sitecore.config'
$ReplaceWith = 'GAXOR'
$LookBehind  = 'sc.variable name=\"dataFolder\" value=\"'
$LookAhead   = '\"'

[RegEx] $Pattern = "(?<=$LookBehind).*(?=$LookAhead)"
$Data = Get-Content -Path $FilePath
$Data -replace $Pattern ,"$1$ReplaceWith$2" | Set-Content -Path $FilePath
