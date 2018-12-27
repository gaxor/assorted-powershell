$FilePath = 'C:\Users\Greg\Documents\GIT\greg-powershell\Sandbox\XML\Cars.xml'
$Algorithm = [Security.Cryptography.HashAlgorithm]::Create("SHA256")
$FileBytes = [io.File]::ReadAllBytes($FilePath)
$Bytes = $Algorithm.ComputeHash($FileBytes)
-Join ($Bytes | ForEach {"{0:x2}" -f $_})
