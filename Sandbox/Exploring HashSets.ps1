$hashSet = New-Object System.Collections.Generic.HashSet[int]
1..10 | foreach{ $hashSet.Add($_) }
$hashSet.RemoveWhere{ $args -lt 5 }
$hashSet

