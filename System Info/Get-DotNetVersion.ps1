Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
Where { $_.PSChildName -Match '^(?!S)\p{L}' } |
Select -ExpandProperty Version |
Measure-Object -Maximum |
Select -ExpandProperty Maximum