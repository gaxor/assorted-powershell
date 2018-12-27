[DSCLocalConfigurationManager()]
Configuration MetaConfiguration
{
    Param
    (
        $CertificateThumbprint
    )

    Node 'localhost'
    {
        Settings
        {
            ConfigurationMode              = 'ApplyOnly'
            ConfigurationModeFrequencyMins = 60
            RefreshMode                    = 'Push'
            RebootNodeIfNeeded             = $False
            CertificateId                  = $CertificateThumbprint
        }
    }
}
