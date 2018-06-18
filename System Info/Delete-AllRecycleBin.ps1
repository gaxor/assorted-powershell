$trash = '$Recycle.Bin'

ForEach ($Drive in get-psdrive -PSProvider FileSystem){
    Remove-Item -Path $Drive.Root$trash -Recurse -Force
}