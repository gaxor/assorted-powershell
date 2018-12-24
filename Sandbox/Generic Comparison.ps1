$watch = [System.Diagnostics.Stopwatch]::new()

# Force garbage collection so it doesn't happen while measuring
[gc]::Collect(); [gc]::WaitForPendingFinalizers(); [gc]::Collect()
$watch.Restart()
$a = 1..3000000
"1: " + $watch.ElapsedMilliseconds