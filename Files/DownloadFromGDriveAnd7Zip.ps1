# Objective: Download files from google drive, compress each directory using 7zip
# Required: Google Deploy Drive File Stream: https://support.google.com/a/answer/7491144?hl=en
# PROBLEM: Somewhere in the process, a "desktop.ini" file is added and zipped
#          I think the fix will be to use the 7zip built-in command line

#Install-Module -Name 7Zip4Powershell -Verbose

$GoogleDriveDir = 'G:\My Drive'
$DestinationDir = 'D:\Books'
$CurrentFiles   = Get-ChildItem $DestinationDir

ForEach ( $CurrentDir in ( Get-ChildItem $GoogleDriveDir -Directory ) )
{
    If ( ( $CurrentDir.Name + '.7z' ) -notin $CurrentFiles.Name )
    {
        $7zParams = @{
            Path             = $CurrentDir.FullName
            ArchiveFileName  = "$DestinationDir\$CurrentDir.7z"
            Format           = 'SevenZip'
            CompressionLevel = 'Ultra'
        }
        Compress-7Zip @7zParams -Verbose
    }
    Else { Write-Warning "$CurrentDir Already exists, skipping" }
}
