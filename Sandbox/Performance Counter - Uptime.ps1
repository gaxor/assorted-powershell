# Uptime with counters
$Counter       = Get-Counter "\System\System Up Time"
$UptimeSeconds = $counter.CounterSamples[0].CookedValue
$UptimeObject  = New-TimeSpan -Seconds $UptimeSeconds

# Uptime formatting
# Standard TimeSpan formatting: https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-timespan-format-strings
# Custom   TimeSpan formatting: https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-timespan-format-strings
'{0:g}' -f $UptimeObject # General short format (culture sensitive)
'{0:c}' -f $UptimeObject # Constant format (not culture sensitive)
'{0:G}' -f $UptimeObject # General long format (culture sensitive)
$UptimeObject.ToString() # Short format via ToString method
