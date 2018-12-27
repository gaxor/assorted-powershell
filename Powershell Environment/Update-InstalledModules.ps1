$Latest = Get-InstalledModule 
ForEach ( $Module in $Latest )
{ 
    Get-InstalledModule $Module.Name -AllVersions |
    Where { $_.Version -ne $Module.Version } |
    Uninstall-Module -Verbose 
}
