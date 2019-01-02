#Requires -Version 4
# Script to return the DNN version for specified computer(s)
# Written by Greg Rowe (May 2017)

Param
(
    [String[]]$ComputerName, # Queries all servers in domain if left empty
    $MailTo   = 'DNNVersionReports@DOMAIN.TLD',
    $FilePath = 'C:\scripts\Get-DNNVersion',
    $FileName = "DNNVersions.$( Get-Date -Format yyyy-MM-dd ).csv"
)

[System.Collections.ArrayList]$Report = @()
$Body =
'
<HTML>
    <HEAD>
        <META http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" />
        <TITLE></TITLE>
    </HEAD>
    <BODY bgcolor=""#FFFFFF"" style=""font-size: Small; font-family: Calibri; color: #000000""><P>
    <br>DNN Version Report below. Also attached as a CSV.<br>
    <style>
        body
        {
            background-color: white;
            font-family:      "Calibri";
        }
        table
        {
            border-width:     1px;
            padding:          5px;
            border-style:     solid;
            border-color:     black;
            border-collapse:  collapse;
        }
        th
        {
            border-width:     1px;
            padding:          2px;
            border-style:     solid;
            border-color:     black;
            background-color: #98C6F3;
        }
        td
        {
            border-width:     1px;
            padding:          2px;
            border-style:     solid;
            border-color:     black;
            background-color: White;
        }
        tr
        {
            text-align:       left;
        }
    </style>
    <!-- Powershell-generated table below -->

'
$EmailParameters  = 
@{
    To          = $MailTo
    From        = 'noreply@DOMAIN.TLD'
    Subject     = 'DNN Version Report'
    Body        = $Body
    BodyAsHtml  = $True
    Attachments = "$( Join-Path $FilePath $FileName )"
    SmtpServer  = 'Localhost'
}

# Clean up local output file(s) for previous run
Get-Item ( Join-Path $FilePath *.csv ) | Remove-Item -ErrorAction SilentlyContinue

# Queue up all domain servers if no targets were specified
If ( !$ComputerName )
{
    $PDCEmulator  = ( [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() ).Domains.PdcRoleOwner.Name
    $ComputerName = Invoke-Command -ComputerName $PDCEmulator -ScriptBlock `
    { ( Get-ADComputer -Filter { ( OperatingSystem -Like 'Windows*' ) -AND ( OperatingSystem -Like '*Server*' ) } ).DNSHostName } `
    | Where { ![String]::IsNullOrEmpty( $_ ) }
}

# Send SQL/DNN query to each computer
ForEach ( $Computer in $ComputerName )
{
    Write-Progress `
    -Activity "Querying $( $ComputerName.Count ) Servers..." `
    -Status $Computer `
    -PercentComplete ( [Array]::IndexOf( $ComputerName, $Computer ) / $ComputerName.Count * 100 )

    $Response = Invoke-Command -ComputerName $Computer -ArgumentList $Computer -ErrorAction SilentlyContinue -ScriptBlock `
    {
        Function Invoke-SQLQuery
        {
            Param ( $SQLInstance )

            [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO' ) | Out-Null
            $Databases = ( New-Object ( 'Microsoft.SqlServer.Management.Smo.Server' ) ".\$SQLInstance" ).Databases `
            | Select-Object Name `
            | Where-Object `
            {
                # Exclude all MSSQL default tables
                $_.Name -NE 'master' -AND `
                $_.Name -NE 'model'  -AND `
                $_.Name -NE 'msdb'   -AND `
                $_.Name -NE 'tempdb'
            }

            ForEach ( $Database in $Databases )
            {
                Try
                {
                    # Prepare database connection
                    $Connection = New-Object System.Data.SQLClient.SQLConnection
                    $Connection.ConnectionString = "Server              = $SQLInstance;
                                                    Database            = $( $Database.Name );
                                                    Trusted_Connection  = True;
                                                    Integrated Security = True;"
                    
                    # Initialize connection to database
                    $Connection.Open()
                    
                    # Prepare SQL query
                    $Command = New-Object System.Data.SQLClient.SQLCommand
                    $Command.Connection  = $Connection
                    $Command.CommandText = $SQLQuery
                    
                    # Execute SQL query
                    $Datatable = New-Object System.Data.DataTable
                    $Datatable.Load( $Command.ExecuteReader() )

                    # Disconnect from database
                    $Connection.Close()
                    
                    # Export selected data
                    [PSCustomObject] @{
                        'LastUpdate'    = $Datatable.CreatedDate
                        'Version'       = "$( $Datatable.Major ).$( $Datatable.Minor ).$( $Datatable.Build )"
                        'DefaultDomain' = $Datatable.SettingValue
                        'DatabaseName'  = $Database.Name
                        'ServerName'    = $Hostname
                    }
                }
                Catch
                {
                    Write-Warning "SQL query failure for database: $( $Database.Name ). Response from $( $Hostname ): "
                    Write-Warning "   $( $Error[0].Exception.Message )"
                    $Connection.Close()
                    Continue
                }
            }
        }

        [System.Collections.ArrayList]$SQLQueryResults = @()
        $Hostname = ( Get-WmiObject Win32_ComputerSystem ).DNSHostName + '.' + ( Get-WmiObject Win32_ComputerSystem ).Domain

        # SQL query to return DNN-specific version info
        $SQLQuery = "SELECT TOP 1 * FROM dbo.version, dbo.PortalSettings 
                     WHERE PortalSettings.SettingName = 'DefaultPortalAlias' 
                     AND PortalSettings.PortalID = 0 
                     ORDER BY version.VersionId DESC"

        # MS SQL instances grabbed from the local registry
        $32bitInstances = ( Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' ).InstalledInstances
        $64bitInstances = ( Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server' ).InstalledInstances
        
        # Merge all instances in one array
        [System.Collections.ArrayList]$SQLInstances = @()
        If ( $32bitInstances ) { $SQLInstances.Add( $32bitInstances ) | Out-Null }
        If ( $64bitInstances ) { $SQLInstances.Add( $64bitInstances ) | Out-Null }

        Switch ( ( $SQLInstances ).Count )
        {
            # If no SQL instance, send warning
            0
            {
                Write-Warning "No SQL instances found on $Hostname"
            }

            # If only one SQL instance, run SQL query with empty SQLInstance
            1
            {
                $Result = Invoke-SQLQuery | Where { $_.Version -NE $NULL -AND $_.Version -NE '..' }
                $SQLQueryResults.Add( $Result ) | Out-Null

                # Output results
                $SQLQueryResults
            }

            # If more than one SQL instance, loop SQL query to each specified SQLInstance
            Default
            {
                ForEach ( $Instance in $SQLInstances )
                {
                    $Result = Invoke-SQLQuery -SQLInstance $Instance | Where { $_.Version -NE $NULL -AND $_.Version -NE '..' }
                    $SQLQueryResults.Add( $Result ) | Out-Null
                    
                    # Clear Result so it can't be duplicated later in error
                    Clear-Variable Result
                }

                # Output results
                $SQLQueryResults
            }
        }
    }
    
    # Add server's response to report
    ForEach ( $Site in $Response )
    {
        # Strip unwanted objects from Site, then add to report
        $Report.Add( ( $Site | Select * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName ) ) | Out-Null
    }
    
    # Clear Response so any following loops don't duplicate an entry into the report
    Clear-Variable Response
}

# Convert results into CSV, and save it to the supplied path
If ( $Report )
{
    # Convert results into CSV, and save it to the supplied path
    $Report | ForEach `
    {
        Export-Csv `
        -InputObject $_ `
        -Path "$( Join-Path $FilePath $FileName )" `
        -NoTypeInformation `
        -Append
    }

    # Convert results into HTML table, and add it to the email body
    $EmailParameters.Body += $Report `
    | Sort-Object -Descending -Property Version `
    | ConvertTo-Html -Fragment

    # Complete email html body
    $EmailParameters.Body += "`r`n    </BODY>"
    $EmailParameters.Body += "`r`n</HTML>"
}
Else
{
    # Send error email if the CSV file was not created
    $EmailParameters.Subject = 'DNN Version Report Failure'
    $EmailParameters.Body    = 
    "The DNNVersion script on $env:COMPUTERNAME queried $( $ComputerName.Count ) servers, but didn't return any data. 
    Either the supplied servers don't have DNN installed (it checks the databases), or there was a problem connecting to the servers (via WinRM)."
    $EmailParameters.Remove('Attachments')
    $EmailParameters.Remove('BodyAsHtml')
}

# Send email with supplied parameters
Send-MailMessage @EmailParameters
