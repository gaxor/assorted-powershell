# Get all available exception types
$Exceptions = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where {$_.Fullname} | ForEach { $_.GetExportedTypes() | Where { $_.Fullname -match 'Exception' } | Select FullName }

# Search exceptions
$Exceptions | Select-String 'sql'

# Explore $Error variable
$Error[0] | select *
$Error[0].Exception.Message
$Error[0].Exception.GetType().FullName