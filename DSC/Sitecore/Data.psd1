# Please complete the following information; it will be used to configure the local server.
# All text after each equal sign (=) must be enclosed in single quotation marks (').

@{ # Do not modify this line

<# ----- Sitecore Server Type ---- #>

    # SitecoreEnvironment acceptable inputs: 'Manager' or 'Delivery'
    SitecoreEnvironment = 'Manager'

<# ----- Website Name In IIS ---- #>

    WebsiteName = 'domain.com'

<# ----- Website Domain (IIS Binding) ---- #>

    WebsiteDomain = 'domain.com'

<# ----- Desired Website Path ---- #>

    # EYSitecoreFiles.zip will be automatically extracted to this directory
    WebsitePath = 'C:\inetpub\domain.com'

<# ----- IIS App Pool User ---- #>

    # AppPoolUser syntax: Domain\UserName or UserName@Domain.tld
    AppPoolUser = ''

<# ----- SQL Database Information ---- #>

    SQLServerIP     = '10.10.10.10'
    SQLServerPort   = '1458'

    # SQL Database Names
    DbName          = 'sitecore-stg'
    DbNameCore      = 'sitecore-stg_core'
    DbNameMaster    = 'sitecore-stg_master'
    DbNameWeb       = 'sitecore-stg_web'
    DbNameSessions  = 'sitecore-stg_Sessions'
    DbNameAnalytics = 'sitecore-stg_analytics'

<# ----- Mongo Database Information ---- #>

    MongoServerIP          = '10.10.10.10'
    
    # Mongo Database Names
    DbNameTracking_Live    = 'sitecore-stg_tracking_live'
    DbNameTracking_History = 'sitecore-stg_tracking_history'
    DbNameTracking_Contact = 'sitecore-stg_tracking_contact'

<# ----- Website SSL Certificate Information ---- #>

    CertificatePath       = 'C:\temp\domain.com.pfx'

    # How to find your certificate's thumbprint: https://msdn.microsoft.com/en-us/library/office/gg318614(v=office.14).aspx
    CertificateThumbprint = '8f5c21134568c54a48864a68f4855c3c2example'

<# ----- Sitecore License ---- #>
    LicenseFilePath = 'C:\temp\license.xml'

<# ------------------------------------------------- #>
<# ----- Do not modify anything below this line ---- #>
<# ------------------------------------------------- #>

    AllNodes = @(
        @{
            NodeName = 'localhost'
            # Allow plain-text passwords - Ensure encryption certificate is present
            PSDscAllowPlainTextPassword = $True
            # MOF Encryption: Certificate Thumbprint
            Thumbprint = $DscCertificate.Thumbprint
        }
    )
}
