Configuration SitecoreConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName xCertificate
    #Import-DscResource -ModuleName xModifyXML # as of 2018 my xModifyXML resource isn't production ready

    Node 'localhost'
    {
        # # Enable LCM Debug Mode - TESTING ONLY; Remove when deploying to production
        # LocalConfigurationManager
        # {
        #     DebugMode = 'all'
        # }

        $Features =
        @(
            'DSC-Service'
            'NET-Framework-Core'
            'NET-Framework-Features'
            'NET-Framework-45-Core'
            'NET-Framework-45-Features'
            'RSAT'
            'RSAT-Feature-Tools'
            'RSAT-Role-Tools'
            'RSAT-SMTP'
            'SMTP-Server'
            'SNMP-Service'
            'Telnet-Client'
            'Web-App-Dev'
            'Web-Asp-Net'
            'Web-Asp-Net45'
            'Web-Basic-Auth'
            'Web-Common-Http'
            'Web-Default-Doc'
            'Web-Dir-Browsing'
            'Web-Filtering'
            'Web-Ftp-Server'
            'Web-Ftp-Service'
            'Web-Health'
            'Web-Http-Errors'
            'Web-Http-Logging'
            'Web-Http-Redirect'
            'Web-IP-Security'
            'Web-ISAPI-Ext'
            'Web-ISAPI-Filter'
            'Web-Lgcy-Mgmt-Console'
            'Web-Metabase'
            'Web-Mgmt-Compat'
            'Web-Mgmt-Console'
            'Web-Mgmt-Tools'
            'Web-Net-Ext'
            'Web-Net-Ext45'
            'Web-ODBC-Logging'
            'Web-Performance'
            'Web-Request-Monitor'
            'Web-Security'
            'Web-Server'
            'Web-Stat-Compression'
            'Web-Static-Content'
            'Web-WebServer'
        )
        $DirectoryPermissions =
        @(
            @{
                User = $ConfigurationData.AppPoolUser
                Path = Join-Path $ConfigurationData.WebsitePath '\Data'
            }
            @{
                User = $ConfigurationData.AppPoolUser
                Path = Join-Path $ConfigurationData.WebsitePath '\Website'
            }
        )
        # $ConnectionStrings =
        # @{
        #     #                                                     [String] XPath = [String] Value
        #     "/connectionStrings/add[@name='core']/@connectionString"             = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbNameCore)"
        #     "/connectionStrings/add[@name='master']/@connectionString"           = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbNameMaster)"
        #     "/connectionStrings/add[@name='web']/@connectionString"              = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbNameWeb)"
        #     "/connectionStrings/add[@name='session']/@connectionString"          = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbNameSessions)"
        #     "/connectionStrings/add[@name='Context']/@connectionString" = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbName)"
        #     "/connectionStrings/add[@name='reporting']/@connectionString"        = "user id=$($SQLcredential.Username);password=$($SqlCredential.GetNetworkCredential().Password);Data Source=$($ConfigurationData.SQLServerIP);Database=$($ConfigurationData.DbNameAnalytics)"
        #     "/connectionStrings/add[@name='analytics']/@connectionString"        = "mongodb://$($ConfigurationData.MongoServerIP)/$($ConfigurationData.DbNameAnalytics)"
        #     "/connectionStrings/add[@name='tracking.live']/@connectionString"    = "mongodb://$($ConfigurationData.MongoServerIP)/$($ConfigurationData.DbNameTracking_Live)"
        #     "/connectionStrings/add[@name='tracking.history']/@connectionString" = "mongodb://$($ConfigurationData.MongoServerIP)/$($ConfigurationData.DbNameTracking_History)"
        #     "/connectionStrings/add[@name='tracking.contact']/@connectionString" = "mongodb://$($ConfigurationData.MongoServerIP)/$($ConfigurationData.DbNameTracking_Contact)"
        #     #"/connectionStrings/add[@name='reporting.apikey']/@connectionString" = ""
        # }
        # $WebConfigSettings =
        # @{
        #     "/configuration/system.web/sessionState/@mode" = "Custom"
        #     "/configuration/system.web/sessionState/@customProvider" = "mssql"
        #     "/configuration/system.web/sessionState/@cookieless" = "false"
        #     "/configuration/system.web/sessionState/@timeout" = "20"
        #     "/configuration/system.web/sessionState/@sessionIDManagerType" = "Sitecore.SessionManagement.ConditionalSessionIdManager"
        # }

        # Install Windows features
        ForEach ( $Feature in $Features )
        {
            WindowsFeature $Feature
            {
                Ensure = 'Present'
                Name   = $Feature
            }
        }

        # Install .NET Framework 4.6.1
        Script InstallDotNet
        {
            GetScript = 
            {
                @{ Result = ".NET Version: $( ( Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' ).Version )" }
            }
            TestScript = 
            {
                # Check installed .NET version
                $DotNet = ( Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' ).Release
        
                # Return True if installed .NET is v4.6.1 (394254) or greater
                $DotNet -ge 394254
            }
            SetScript = 
            {
                Function Install-DotNet
                {
                    Param ( $DownloadPath )
        
                    $Uri = 'https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe'
                    $FileName = Split-Path $Uri -Leaf
                    $Destination = Join-Path $DownloadPath $FileName
        
                    New-Item $DownloadPath -ItemType Directory -ErrorAction SilentlyContinue
                    Remove-Item $Destination -ErrorAction SilentlyContinue
        
                    # Download file
                    ( New-Object System.Net.WebClient ).DownloadFile( $Uri, $Destination )
        
                    # Install .NET
                    Start-Process $Destination -ArgumentList ( '/quiet', '/norestart' ) -Wait
        
                    # Cleanup
                    Remove-Item $Destination
                }
        
                Install-DotNet -DownloadPath 'C:\'
            }
        }

        # Install UrlRewrite 2.0
        Script InstallUrlRewrite
        {
            DependsOn = '[WindowsFeature]Web-Server'
            GetScript = 
            {
                @{ Result = 'UrlRewrite' }
            }
            TestScript = 
            {
                # Return True if UrlRewrite is present
                Test-Path -Path ( Join-Path $Env:SystemRoot 'System32\inetsrv\rewrite.dll' )
            }
            SetScript = 
            {
                $Uri = 'http://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi'
                $FileName    = Split-Path $Uri -Leaf
                $Destination = Join-Path 'C:\' $FileName
        
                # Download file
                ( New-Object System.Net.WebClient ).DownloadFile( $uri,$Destination )
        
                # Install UrlRewrite
                Start-Process $Destination -ArgumentList ( '/quiet', '/norestart' ) -Wait

                # Cleanup
                Remove-Item $Destination
            }
        }

        # Remove 'Default Web Site'
        xWebsite DefaultWebSite
        {
            DependsOn = '[WindowsFeature]Web-Server'
            Ensure    = 'Absent'
            Name      = 'Default Web Site'
        }

        # Install Web Certificate
        xPfxImport Certificate
        {
            Ensure     = 'Present'
            Thumbprint = $ConfigurationData.CertificateThumbprint -replace '[^a-zA-Z0-9]'
            Path       = $ConfigurationData.CertificatePath
            Credential = $CertificateCredential
            Location   = 'LocalMachine'
            Store      = 'WebHosting'
        }

        # Create website directory
        File WebsiteDirectory
        {
            DestinationPath = $ConfigurationData.WebsitePath
            Ensure          = 'Present'
            Type            = 'Directory'
        }

        # Copy Sitecore files
        Archive SitecoreDefaultFiles
        {
            DependsOn   = '[WindowsFeature]Web-Server',
                          '[File]WebsiteDirectory'
            Ensure      = 'Present'
            Path        = Join-Path ( Split-Path -Path $PSScriptRoot -Parent ) SitecoreDefaultFiles.zip
            Destination = $ConfigurationData.WebsitePath
            Validate    = $True
            Force       = $True
        }

        # # Copy Sitecore files
        # Archive CustomizedFiles
        # {
        #     DependsOn   = '[Archive]SitecoreDefaultFiles'
        #     Ensure      = 'Present'
        #     Path        = Join-Path ( Split-Path -Path $PSScriptRoot -Parent ) CustomizedFiles.zip
        #     Destination = $ConfigurationData.WebsitePath
        #     Validate    = $True
        #     Force       = $True
        # }

        # ForEach ( $Connection in $ConnectionStrings.GetEnumerator() )
        # {
        #     xXmlNode "ConnectionStrings_$( $Connection.Key )"
        #     {
        #         Ensure   = "Present"
        #         FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
        #         XPath    = $Connection.Key
        #         Value    = $Connection.Value
        #     }
        # }

        Script PerformanceCounters
        {
            DependsOn = '[Archive]SitecoreDefaultFiles',
                        '[xWebAppPool]AppPool'
            GetScript = 
            {
                @{ Result = 'Group Members: Performance Monitor Users' }
            }
            TestScript =
            {
                # Returns true if Network Service account is in the group, false if not
                $IsMember = Get-LocalGroupMember -Group 'Performance Monitor Users' -Member 'NT AUTHORITY\NETWORK SERVICE' -ErrorAction SilentlyContinue
                ( $IsMember ).Name -eq 'NT AUTHORITY\NETWORK SERVICE'
            }
            SetScript =
            {
                Add-LocalGroupMember -Group 'Performance Monitor Users' -Member 'NT AUTHORITY\NETWORK SERVICE'
            }
        }

        # Set Sitecore NTFS permissions
        ForEach ( $Permission in $DirectoryPermissions )
        {
            cNtfsPermissionEntry "Permission.$( $Permission.User ):$( $Permission.Path )"
            {
                DependsOn                = '[Archive]SitecoreDefaultFiles',
                                           '[xWebAppPool]AppPool'
                Ensure                   = 'Present'
                Path                     = $Permission.Path
                Principal                = $Permission.User
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'Modify'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $False
                    }
                )
            }

            # Enforce NTFS permission inheritance
            cNtfsPermissionsInheritance "PermissionInheritance.$( $Permission.User ):$( $Permission.Path )"
            {
                DependsOn = '[Archive]SitecoreDefaultFiles',
                            '[xWebAppPool]AppPool'
                Path      = $Permission.Path
                Enabled   = $True
            }
        }

        # Create application pool
        xWebAppPool AppPool
        {
            DependsOn    = '[WindowsFeature]Web-Asp-Net45'
            Ensure       = 'Present'
            Name         = $ConfigurationData.WebsiteName
            identityType = 'SpecificUser'
            Credential   = $AppPoolCredential
        }

        # Set up Sitecore site in IIS
        Switch ( $ConfigurationData.SitecoreEnvironment )
        {
            Manager
            {
                xWebSite Sitecore
                {
                    DependsOn       = '[Archive]SitecoreDefaultFiles',
                                      '[xWebAppPool]AppPool',
                                      '[xPfxImport]Certificate'
                    Name            = $ConfigurationData.WebsiteName
                    Ensure          = 'Present'
                    State           = 'Started'
                    PhysicalPath    = Join-Path $ConfigurationData.WebsitePath '\Website'
                    ApplicationPool = $ConfigurationData.WebsiteName
                    BindingInfo     = @(
                        # Main Domain
                        MSFT_xWebBindingInformation
                        {
                                Protocol  = 'HTTP'
                                Port      = 80
                                HostName  = '*'
                                IPAddress = '*'
                        }
                        MSFT_xWebBindingInformation
                        {
                                Protocol              = 'HTTPS'
                                Port                  = 443
                                CertificateStoreName  = 'WebHosting'
                                CertificateThumbprint = $ConfigurationData.CertificateThumbprint -replace '[^a-zA-Z0-9]'
                                HostName              = '*'
                                IPAddress             = '*'
                                SSLFlags              = '1'
                        }
                    )
                }

                # # Config file settings
                # xXmlNode WebConfigProviderMssql
                # {
                #     Ensure   = "Present"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='mssql']/@sessionType"
                #     Value    = "Standard"
                # }
                # xXmlNode WebConfigProviderMongo
                # {
                #     Ensure   = "Present"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='mongo']"
                # }
                # xXmlNode WebConfigProviderRedis
                # {
                #     Ensure   = "Present"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='redis']"
                # }
            }

            Delivery
            {
                xWebSite Sitecore
                {
                    DependsOn       = '[Archive]SitecoreDefaultFiles',
                                      '[xWebAppPool]AppPool',
                                      '[xPfxImport]Certificate'
                    Name            = $ConfigurationData.WebsiteName
                    Ensure          = 'Present'
                    State           = 'Started'
                    PhysicalPath    = Join-Path $ConfigurationData.WebsitePath '\Website'
                    ApplicationPool = $ConfigurationData.WebsiteName
                    BindingInfo     = @(
                        # Main Domain
                        MSFT_xWebBindingInformation
                        {
                                Protocol  = 'HTTP'
                                Port      = 80
                                HostName  = '*'
                                IPAddress = '*'
                        }
                        MSFT_xWebBindingInformation
                        {
                                Protocol              = 'HTTPS'
                                Port                  = 443
                                CertificateStoreName  = 'WebHosting'
                                CertificateThumbprint = $ConfigurationData.CertificateThumbprint -replace '[^a-zA-Z0-9]'
                                HostName              = '*'
                                IPAddress             = '*'
                                SSLFlags              = '1'
                        }
                    )
                }

                # # Config file settings
                # xXmlNode WebConfigProviderMssql
                # {
                #     Ensure   = "Present"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='mssql']/@sessionType"
                #     Value    = "Private"
                # }
                # xXmlNode WebConfigProviderMongo
                # {
                #     Ensure   = "Absent"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='mongo']"
                # }
                # xXmlNode WebConfigProviderRedis
                # {
                #     Ensure   = "Absent"
                #     FilePath = "$( $ConfigurationData.WebsitePath )\Website\web.config"
                #     XPath    = "/configuration/system.web/sessionState/providers/add[@name='redis']"
                # }
            }
        }

        # Configure IIS Rewrite rules (HTTP to HTTPS)
        Script RewriteRules
        {
            DependsOn = '[xWebSite]Sitecore'#,
                        #'[Script]InstallUrlRewrite'
            GetScript =
            {
                @{ Result = 'HTTP/S to HTTPS redirect' }
            }
            TestScript =
            {
                Function Test-Equivalence ( $Object, $ReferenceObject )
                {
                    If ( $Object )
                    {
                        If ( $Object -eq $ReferenceObject )
                        { Continue }
                        Else
                        { Return $False }
                    }
                }

                Function Get-NestedProperty ( $Object, $Value )
                {
                    ForEach ( $Nested in $Value.split( '.' ) )
                    { $Object = Invoke-Expression "`$Object.$Nested" }
                
                    Return $Object
                }

                # Declare desired URL Rewrite settings (for hash table comparison)
                $Desired = @{
                    RuleName           = 'HTTP/S to HTTPS Redirect'
                    RulePatternSyntax  = 'ECMAScript'
                    RuleStopProcessing = 'True'
                    MatchPattern       = '.*'
                    ConditionInput     = '{HTTPS}'
                    ConditionPattern   = 'ON'
                    ConditionNegate    = 'true'
                    ActionType         = 'Redirect'
                    ActionUrl          = 'https://{HTTP_HOST}{REQUEST_URI}'
                }
                $Locations = @{
                    RuleName           = 'name'
                    RulePatternSyntax  = 'PatternSyntax'
                    RuleStopProcessing = 'stopProcessing'
                    MatchPattern       = "GetChildElement('match').GetAttribute('url').Value"
                    ConditionInput     = 'conditions.Collection.input'
                    ConditionPattern   = 'conditions.Collection.pattern'
                    ConditionNegate    = 'conditions.Collection.negate'
                    ActionType         = 'action.type'
                    ActionUrl          = 'action.url'
                }

                # Get current URL Rewrite settings
                $PSPath             = "IIS:\Sites\$( $ConfigurationData.WebsiteName )"
                $CurrentRewriteRule = Get-WebConfigurationProperty -PSPath $PSPath -Filter 'system.webServer/rewrite/rules' -Name '.' |
                    Select -ExpandProperty Collection |
                    Where { $_.name -eq 'HTTP to HTTPS Redirect' }

                If ( !$CurrentRewriteRule )
                { Return $False }
                Else
                {
                    ForEach ( $Setting in $Desired.GetEnumerator() )
                    {
                        If ( Get-NestedProperty -Object $CurrentRewriteRule -Value $Locations[$Setting.Key] )
                        {
                            Test-Equivalence `
                                -Object ( Get-NestedProperty -Object $CurrentRewriteRule -Value $Locations[$Setting.Key] ) `
                                -ReferenceObject $Desired[$Setting.Key]
                        }
                        Else
                        { Return $False } 
                    }
                }
                # If we've gotten this far, desired state is present
                Return $True
            }
            SetScript =
            {
                # Declare desired URL Rewrite settings (for splatting)
                $PSPath       = "IIS:\Sites\$( $ConfigurationData.WebsiteName )"
                $RulePath     = "system.webserver/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']"
                $RewriteRule  = @{
                    PSPath = $PSPath
                    Filter = 'system.webserver/rewrite/rules'
                    Name   = '.'
                    Value  = @{
                        name           = 'HTTP/S to HTTPS Redirect'
                        patternSyntax  = 'ECMAScript'
                        stopProcessing = 'True'
                    }
                }
                $MatchPattern = @{
                    PSPath = $PSPath
                    Filter = "$RulePath/match"
                    Name   = 'url'
                    Value  = '.*'
                }
                $Conditions   = @{
                    PSPath = $PSPath
                    Filter = "$RulePath/conditions"
                    Name   = '.'
                    Value  = @{
                        input   = '{HTTPS}'
                        pattern = 'ON'
                        negate  = 'true'
                    }
                }
                $Actions      = @{
                    PSPath = $PSPath
                    Filter = "$RulePath/action"
                    Name   = '.'
                    Value  = @{
                        type = 'Redirect'
                        url  = 'https://{HTTP_HOST}{REQUEST_URI}'
                    }
                }

                # Create URL Rewrite rules
                Try
                {
                    Start-WebCommitDelay

                    Try { Add-WebConfigurationProperty @RewriteRule }
                    Catch [System.Runtime.InteropServices.COMException] { Continue }
                    Catch { Set-WebConfigurationProperty @RewriteRule }
                    Set-WebConfigurationProperty @MatchPattern
                    Set-WebConfigurationProperty @Conditions
                    Set-WebConfigurationProperty @Actions

                    Stop-WebCommitDelay -Commit $True
                    Write-Verbose 'Settings applied successfully. Changes written to disk.'
                }
                Catch
                {
                    Stop-WebCommitDelay -Commit $False
                    Write-Verbose 'Settings failed to apply. Changes not written to disk.'
                }
            }
        }

        # Create Document Upload Directory
        File DocumentUploadDir
        {
            DependsOn       = '[Archive]SitecoreDefaultFiles'
            DestinationPath = Join-Path $ConfigurationData.WebsitePath 'Website\Files\Documents'
            Ensure          = 'Present'
            Type            = 'Directory'
            Force           = $True
        }

        # Set Sitecore Database Connections
        File DatabaseConnectionSettings
        {
            DependsOn       = '[Archive]SitecoreDefaultFiles'
            DestinationPath = Join-Path $ConfigurationData.WebsitePath 'Website\App_Config\ConnectionStrings.config'
            Ensure          = 'Present'
            Type            = 'File'
            Contents        = $ConfigurationData.ConnectionStrings
            Force           = $True
        }

        # Copy Sitecore license file
        File SitecoreLicense
        {
            DependsOn       = '[Archive]SitecoreDefaultFiles'
            DestinationPath = Join-Path $ConfigurationData.WebsitePath 'Data\license.xml'
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = $ConfigurationData.LicenseFilePath
            Force           = $True
        }

        # Sitecore website data path variable
        Script SitecoreDataPath
        {
            DependsOn = '[Archive]SitecoreDefaultFiles'
            GetScript =
            {
                @{ Result = 'SitecoreDataPath' }
            }
            TestScript =
            {
                $FilePath = Join-Path $Using:ConfigurationData.WebsitePath 'Website\App_Config\Sitecore.config'
                $FileRead = New-Object System.IO.StreamReader -ArgumentList $FilePath
                $Desired  = Join-Path $Using:ConfigurationData.WebsitePath 'Data'

                # RegEx syntax. Text behind and ahead of capture group
                # Be sure to escape double-quotes with a backslash for the regex engine
                $LookBehind = 'sc.variable name=\"dataFolder\" value=\"'
                $LookAhead = '\"'
                [RegEx] $Pattern = "(?<=$LookBehind).*(?=$LookAhead)"

                # Search current line for pattern
                While ( $Line = $FileRead.ReadLine() )
                {
                    If ( [RegEx]::Match( $Line, $Pattern ).Value -eq $Desired )
                    {
                        $FileRead.Close()
                        Return $True
                    }
                }

                $FileRead.Close()
                Return $False
            }
            SetScript =
            {
                $FilePath = Join-Path $Using:ConfigurationData.WebsitePath 'Website\App_Config\Sitecore.config'

                # Replace whatever regex finds with the following
                $ReplaceWith = Join-Path $Using:ConfigurationData.WebsitePath 'Data'

                # RegEx syntax. Text behind and ahead of capture group
                # Be sure to escape double-quotes with a backslash for the regex engine
                $LookBehind = 'sc.variable name=\"dataFolder\" value=\"'
                $LookAhead = '\"'
                [RegEx] $Pattern = "(?<=$LookBehind).*(?=$LookAhead)"

                $Data = Get-Content -Path $FilePath
                $Data -replace $Pattern ,"$1$ReplaceWith$2" | Set-Content -Path $FilePath
            }
        }
    }
}
