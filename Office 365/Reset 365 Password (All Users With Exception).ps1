$exclude = @(
    'user1@domain.com'
    'user2@domain.com'
)

$allusers = Get-MsolUser -All
$allusers | where {$_.UserPrincipalName -notin $exclude} | Set-MsolUserPassword -ForceChangePasswordOnly $true -ForceChangePassword $true
