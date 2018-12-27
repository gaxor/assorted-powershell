$UserName = 'myuser'
$Password = 'mypass'

# use pscredential to encrypt
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,( $Password | ConvertTo-SecureString -AsPlainText -Force )
$Credential.GetNetworkCredential().Password

# use securestring to encrypt
$SecureString       = $Password | ConvertTo-SecureString -AsPlainText -Force
$SecureStringAsText = $SecureString | ConvertFrom-SecureString

# use marshal to decrypt from securestring
$DbPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $Credential.Password )
# or
$DbPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $SecureString )

[System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $DbPassword )
