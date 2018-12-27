# Good XML resource: https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-data-basics-xml/

$CarsFilePath = 'C:\temp\Cars.xml'
[xml] $Cars = Get-Content -Path $CarsFilePath

###############################

# Find data via type
$Cars.ChildNodes
$Cars.ChildNodes | % { $_.gettype() }
$Cars.ChildNodes.Car[0]


###############################

# Add XML data
$Cars.ChildNodes.car
( $Cars.ChildNodes.car.Where({$_.Make -eq 'Ford'}) | Select -First 1 ).Seats = '5000'

# Save to file
$Cars.Save( $CarsFilePath )

# Save using absolute paths (XML uses PS working directory)
Get-Location                     # displays PowerShell location
[Environment]::CurrentDirectory  # displays working directory