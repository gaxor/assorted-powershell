# Microsoft's instructions: https://support.office.com/en-us/article/Manage-who-can-create-Office-365-Groups-4c46c8cb-17d0-44b5-9776-005fced8e618

Install-Module AzureADPreview -MinimumVersion 2.0.0.137 -Verbose
Connect-AzureAD
Import-Module AzureADPreview

$GroupName = "365GroupCreators"

# Get template stuff
$Template = Get-AzureADDirectorySettingTemplate | where {$_.DisplayName -eq 'Group.Unified'}
$Setting = $Template.CreateDirectorySetting()

# Set "Directory setting"
New-AzureADDirectorySetting -DirectorySetting $Setting

# Add group creation constraints to settings
$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id
$Setting["EnableGroupCreation"] = $False
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid

# Apply settings to group
Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $Setting

# Verify it worked
(Get-AzureADDirectorySetting).Values
