Overview:
    The provided scripts will deploy a Sitecore website on the local computer.
    This needs to be run individually on each server you wish to deploy to.

Prerequisites:
    - SQL and Mongo databases are assumed to be outsourced services, and should be set up separately from this script
        - Ensure SQL databases are restored to SQL cluster
    DB user (needs to be AD user to be used for app pool and DB access)
        - DB user role membership:
        -    sitecore-[env] database:
        -       db_datareader
        -       db_datawriter
        -       public
        -       db_owner
        -    Master, Web, Analytics, Sessions databases:
        -       db_datareader
        -       db_datawriter
        -       public
        -    Core database:
        -       db_datareader
        -       db_datawriter
        -       public
        -       aspnet_Membership_BasicAccess
        -       aspnet_Membership_FullAccess
        -       aspnet_Membership_ReportingAccess
        -       aspnet_Profile_BasicAccess
        -       aspnet_Profile_FullAccess
        -       aspnet_Profile_ReportingAccess
        -       aspnet_Roles_BasicAccess
        -       aspnet_Roles_FullAccess
        -    OnlineSchedule database:
        -       db_datareader
        -       execute
    - OS is assumed to be Windows Server 2012 R2
    - Copy the following files to each server
        from windows install iso: \sources\sxs to E:\sxs
        sitecore scripts (expand to c:\dscfiles)
        sitecore site files (as c:\dscfiles\SitecoreDefaultFiles.zip)
        DSC modules (unzip to C:\Program Files\WindowsPowerShell\Modules)
        WMF 5.1 installer (kb3191564)
        URL rewrite 2.0 installer
    - Install WMF 5.1
    - Install URL rewrite mofule
    - Set up proxy for web access if needed for internet access
    - Internet access to the following URLs:
        - http://download.windowsupdate.com (.NET installer, WMF installer)
        - http://download.microsoft.com (Url-Rewrite Installer, .NET installer)
        - https://go.microsoft.com (NuGet Package Manager, PowerShell Gallery Modules)
        - https://oneget.org (NuGet Package Manager)
        - sls.update.microsoft.com
        - sls.update.microsoft.com.nsatc.net
        - fe2.update.microsoft.com
        - fe2.update.microsoft.com.nsatc.net
    - Provide local path to website's desired SSL certificate file (.pfx)
        - This script assumes the following about the certificate:
            - Requires a password to open
            - Is a Multi-Domain (SAN) Certificate with all necessary DNS Names
    - Provide local path to Sitecore license file (license.xml)

Deployment Steps:
    1: Extract sitecore.zip to a local directory (e.g. "C:\Temp")
    2: In this new directory, edit and fill out (right-click, select Edit) the included data file (Data.psd1)
    3: Run Deploy.cmd and follow the prompts for the following info:
        - MSSQL username and password
        - Website SSL certificate password
    4: [Recommended] Update Windows to acquire the latest security patches for newly-installed roles & features
    
    After running the script:
    - Change the IIS App Pool user for the website to match the SQL DB user (should be AD account)
    - Update connectionString.config file with required IPs & credentials
    - Ensure the web.config file differences match the CD/CM server:
        Content Manager:
            <sessionState mode="InProc" cookieless="false" timeout="20" sessionIDManagerType="Sitecore.SessionManagement.ConditionalSessionIdManager">
            <providers>
                <add name="mongo" type="Sitecore.SessionProvider.MongoDB.MongoSessionStateProvider, Sitecore.SessionProvider.MongoDB" sessionType="Standard" connectionStringName="session" pollingInterval="2" compression="true" />
                <add name="mssql" type="Sitecore.SessionProvider.Sql.SqlSessionStateProvider, Sitecore.SessionProvider.Sql" sessionType="Standard" connectionStringName="session" pollingInterval="2" compression="true" />
                <add name="redis" type="Sitecore.SessionProvider.Redis.RedisSessionStateProvider, Sitecore.SessionProvider.Redis" applicationName="Application" connectionString="session" pollingInterval="2" compression="true" />
            </providers>
            </sessionState>

        Content Delivery:
            <sessionState mode="Custom" customProvider="mssql" cookieless="false" timeout="20" sessionIDManagerType="Sitecore.SessionManagement.ConditionalSessionIdManager">
            <providers>
                <add name="mssql" type="Sitecore.SessionProvider.Sql.SqlSessionStateProvider, Sitecore.SessionProvider.Sql" sessionType="Private" connectionStringName="session" pollingInterval="2" compression="true" />
            </providers>
            </sessionState>

    - Ensure the following sections are set in the web.config:
        Location: /configuration/system.webServer/rewrite
            <outboundRules>
                <rule name="Modify Server header value" patternSyntax="Wildcard">
                    <match serverVariable="RESPONSE_SERVER" pattern="*" />
                    <action type="Rewrite" value="" />
                </rule>
            </outboundRules>

        Location: /configuration/system.webServer/httpProtocol/customHeaders
            <remove name="X-Powered-By" />
            <add name="X-Xss-Protection" value="1; mode=block" />
            <add name="X-Content-Type-Options" value="nosniff" />
            <add name="Referrer-Policy" value="strict-origin" />
            <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
            <add name="Access-Control-Allow-Origin" value="*" />
            <add name="Content-Security-Policy" value="default-src 'self' https://ssl.google-analytics.com ; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.google.com https://www.gstatic.com/ http://*.brightcove.com http://*.brightcove.net http://vjs.zencdn.net/; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://fonts.gstatic.com https://www.google.com; img-src 'self' https://*.akamaihd.net/ http://*.brightcove.com http://*.brightcove.net https://www.google.com data:; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com http://*.brightcove.com http://*.brightcove.net data:; connect-src 'self' https://*.akamaihd.net/ http://*.brightcove.com http://*.brightcove.net; frame-src 'self' https://www.google.com http://*.sitecore.net https://*.sitecore.net; worker-src 'self' blob:; media-src 'self' blob:;" />

        Location: /configuration/system.webServer/security/requestFiltering
            <verbs allowUnlisted="false" >
                <add verb="GET" allowed="true" />
                <add verb="POST" allowed="true" />
                <add verb="PUT" allowed="true" />
                <add verb="DELETE" allowed="true" />
            </verbs>

    - Update sitecore.config file to reflect proper SMTP settings
    - Add IIS virtual directory in /Website/Files called "Documents" to encrypted fileshare (File Server's UNC share)
    - secpol.msc > "Local Policies" > "UserRights Assignment" > "Act as part of the operating system" > Add App Pool user > restart IIS
    - Encrypt connectionStrings with the fololowing command:
        C:\windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -pef connectionStrings {Website Path}
        (Decrypt by replacing -pef with -pdf)
    - Reset IIS App Pool

Post-Deployment Notes:
    Microsoft Desired State Configuration (DSC) stores its generated configuration scripts in C:\Windows\System32\Configuration\
    The provided DSC configuration will encrypt these files with a localhost self-signed certificate
