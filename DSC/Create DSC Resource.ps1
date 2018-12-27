#Find-Module -Name xDSCResourceDesigner | Install-Module -Force

$NewItemParams = @{
    Path     = "$env:ProgramFiles\WindowsPowerShell\Modules"
    Name     = 'xModifyXML'
    ItemType = 'Directory'
}
New-Item @NewItemParams

$NewModuleManifestParams = @{
    Path              = "$env:ProgramFiles\WindowsPowerShell\Modules\xModifyXML\xModifyXML.psd1"
    Guid              = (([guid]::NewGuid()).Guid)
    Author            = 'Greg Rowe'
    ModuleVersion     = 0.01
    Description       = 'DSC Resource Module for ModifyXML'
    PowerShellVersion = 4.0
    FunctionsToExport = '*.TargetResource'
}
New-ModuleManifest @NewModuleManifestParams

# Define DSC resource properties 

$DataCollectorSetName = New-xDscResourceProperty -Type String -Name DataCollectorSetName -Attribute Key
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent"
$XmlTemplatePath = New-xDscResourceProperty -Name XmlTemplatePath -Type String -Attribute Required

# Create the DSC resource 
# This gave errors and didn't work properly. I haven't looked into why yet
$NewxDscResourceParams = @{
    Name         = 'xModifyXML'
    Property     = $DataCollectorSet,$Ensure,$XmlTemplatePath
    Path         = "$env:ProgramFiles\WindowsPowerShell\Modules\xModifyXML"
    ClassVersion = 1.0
    FriendlyName = 'xModifyXML'
    Force        = $true
}
New-xDscResource @NewxDscResourceParams
