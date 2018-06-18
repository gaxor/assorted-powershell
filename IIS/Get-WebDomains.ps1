# Source: https://stackoverflow.com/a/15529399

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
Import-Module WebAdministration

Get-WebBinding | ForEach `
{
    $Name = $_.ItemXPath -Replace '(?:.*?)name=''([^'']*)(?:.*)', '$1'
    New-Object psobject -Property `
    @{
        Name    = $Name
        Binding = $_.bindinginformation.Split(":")[-1]
    }
} `
| Group-Object -Property Name `
| Format-Table Name, @{ N = 'Domains'; E = { $_.Group.Binding -join "`n" } } -Wrap -AutoSize