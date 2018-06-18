#Requires -Version 2.0
#Requires -RunAsAdministrator

Param
(
    $ProfileName,
    $AccessKey,
    $SecretKey,
    $DefaultRegion
)

$Defaults = @{
    StoreAs   = $ProfileName
    AccessKey = $AccessKey
    SecretKey = $SecretKey
}

Set-AWSCredentials @Defaults

If($DefaultRegion)
{
    Set-DefaultAWSRegion $DefaultRegion
    Initialize-AWSDefaults -ProfileName $ProfileName
}