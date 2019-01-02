$drive = 'F'
$index = '4'
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

$installed = Get-WindowsFeature | Where { $_.installed -eq $true }
ForEach ($Feature in $Features)
{
    If ( $Feature -notin $installed.name )
    {
        Install-WindowsFeature $Feature –Source "wim:$($drive):\sources\install.wim:$($index)"
    }
}