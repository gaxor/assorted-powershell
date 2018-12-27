Param
(
	[Parameter(Mandatory)]
    $ComputerName,
    $SourceFiles  = '\\server\share\putty.exe',
    $Destination  = 'd:\temp\dsc\putty.exe',
    $Dir          = 'd:\temp\dsc',
	$MofPath      = 'C:\DSCData'
)

Configuration CopyFile
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node $ComputerName
    {
		# Make sure $Dir exists
        File Dir
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $Dir
        }
        
		# Copy files to destination
        File CopyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = $SourceFiles
            DestinationPath = $Destination
            DependsOn       = '[File]Dir'
        }
    }
}

CopyFile -OutputPath $MofPath
Start-DscConfiguration -ComputerName $ComputerName -Path $MofPath -Force -Wait -Verbose
