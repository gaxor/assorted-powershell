Find-PackageProvider -Name NuGet | Install-PackageProvider
Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet