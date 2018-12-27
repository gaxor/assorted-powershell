# DSC configuration: MongoDB server setup
# Written by Greg Rowe (June 2017)
# Not production ready

Param
(
    $ComputerName = 'localhost',
    [ValidatePattern( '*.zip' )]
    $SourceZip    = "$env:SystemDrive\DSCData\Source.zip",
    $UnzipPath    = ( Get-Item $SourceZip ).DirectoryName,
    $MongoFolder  = 'D:\MongoDB'
)

Function Get-MSIFileInformation
{
    # Function by Nickolaj Andersen
    Param
    (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Path,
 
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet( 'ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion' )]
        [String]
        $Property
     )
    Process
    {
        # Read property from MSI database
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $MSIDatabase      = $WindowsInstaller.GetType().InvokeMember( 'OpenDatabase', 'InvokeMethod', $Null, $WindowsInstaller, @( $Path.FullName, 0 ) )
        $Query            = "SELECT Value FROM Property WHERE Property = '$( $Property )'"
        $View             = $MSIDatabase.GetType().InvokeMember( 'OpenView', 'InvokeMethod', $Null, $MSIDatabase, ( $Query ) )
        $View.GetType().InvokeMember( 'Execute', 'InvokeMethod', $Null, $View, $Null )
        $Record           = $View.GetType().InvokeMember( 'Fetch', 'InvokeMethod', $Null, $View, $Null )
        $Value            = $Record.GetType().InvokeMember( 'StringData', 'GetProperty', $Null, $Record, 1 )

        # Commit database and close view
        $MSIDatabase.GetType().InvokeMember( 'Commit', 'InvokeMethod', $Null, $MSIDatabase, $Null )
        $View.GetType().InvokeMember( 'Close', 'InvokeMethod', $Null, $View, $Null )           
        $MSIDatabase = $Null
        $View = $Null

        Return $Value
    }
    End {
        # Run garbage collection and release ComObject
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject( $WindowsInstaller ) | Out-Null
        [System.GC]::Collect()
    }
}

Configuration SitecoreMongoDBServer
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $ComputerName
    {
        $Features =
        @(
            'DSC-Service'
        )
        $Directories =
        @(
            $MongoFolder
            "$MongoFolder\data\db"
            "$MongoFolder\data\log"
        )

        ForEach ( $Feature in $Features )
        {
            WindowsFeature $Feature
            {
                Name   = $Feature
                Ensure = 'Present'
            }
        }

        ForEach ( $Dir in $Directories )
        {
            File MongoFolder
            {
                Type            = 'Directory'
                DestinationPath = $Dir
                Ensure          = 'Present'
            }
        }
        
        File MongoConfigFile
        {
            DependsOn       = '[File]MongoFolder'
            Type            = 'File'
            SourcePath      = "$UnzipPath\mongod.cfg"
            DestinationPath = "$MongoFolder\mongod.cfg"
            Ensure          = 'Present'
        }

        Archive SourceFiles
        {
            Path        = $SourceZip
            Destination = "$UnzipPath\Source"
            Ensure      = 'Present'
            Validate    = $True # syntax not confirmed
        }

        Package MongoDB
        {
            DependsOn = '[Archive]SourceFiles'
            Path      = "$UnzipPath\Mongo.msi"
            Arguments = 'ADDLOCAL="all"'
            Name      = Get-MSIFileInformation -Property ProductName
            ProductId = ''
            Ensure    = 'Present'
        }


    }
}

# Compile and push MOF to specified computer
SitecoreMongoDBServer
Start-DscConfiguration -Path .\SitecoreMongoDBServer -ComputerName $ComputerName -Force -Wait -Verbose
