# https://developer.ringcentral.com/api-explorer/latest/index.html#/

$ClientSecret = 'secrettext'

$GetParams = @{
    Uri         = "$ApiRoot/$ApiCategory/$( $Response.ID ).$BodyClass".ToLower()
    Headers     = $Headers
    ContentType = $ContentType
    Method      = 'Get'
    ErrorAction = 'SilentlyContinue'
}
$GetResponse = Invoke-RestMethod @GetParams

<#
    curl -X POST 
    --header "Content-Type: application/json" 
    --header "Accept: application/json" 
    --header "Authorization: Bearer %accessToken%" 
    -d "{\"from\":{\"phoneNumber\":\"+15555555555\"},\"to\":[{\"phoneNumber\":\"+14445555555\"}],\"text\":\"Hello, World!\"}" 
    "https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/sms"
#>

$Headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
$Headers.Add( 'Content-Type', 'application/json' )
$Headers.Add( 'Accept', 'application/json' )
$Headers.Add( 'Authorization', "Bearer $ClientSecret" )
$Headers

$Uri = 'https://platform.devtest.ringcentral.com/restapi/v1.0/glip/groups'

$GetParams = @{
    Uri         = $Uri.ToLower()
    Headers     = $Headers
    ContentType = 'application/json'
    Method      = 'Get'
    #ErrorAction = 'SilentlyContinue'
}
$GetResponse = Invoke-RestMethod @GetParams

$api_server_url = "https://platform.devtest.ringcentral.com"
$media_server_url = "https://media.devtest.ringcentral.com:443"
$username = ''
$password = ''
$extension = ''
$app_key = ''
$log_path = "C:\scripts\log\ringcentral.log"


# ------- tests --------

$AuthUri = "https://platform.devtest.ringcentral.com/restapi/oauth/authorize?client_id=$ID&prompt=login%20consent&redirect_uri=http%3A%2F%2Fmyapp%2Eexample%2Ecom%2Foauthredirect HTTP/1.1"
Invoke-RestMethod -Uri $AuthUri -Headers $Headers -ContentType 'application/json'

$Uri = 'https://platform.devtest.ringcentral.com/restapi/oauth/token'
Invoke-RestMethod -Uri $Uri -Headers $Headers -ContentType 'application/json'
