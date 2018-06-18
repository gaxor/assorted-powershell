$UserName = @( 'username','username2' )
$Domain   = 'DOMAIN.TLD'

ForEach ( $User in $UserName )
{
    $AdminGroup = [ADSI]"WinNT://localhost/Administrators,group"
    $User       = [ADSI]"WinNT://$Domain/$User,user"
    $AdminGroup.Add( $User.Path )
}
