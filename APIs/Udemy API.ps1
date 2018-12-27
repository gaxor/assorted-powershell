# This has not been tested yet, and could very well be wrong
# Udemy API: https://www.udemy.com/developers/
# Udemy API (Users): https://www.udemy.com/developers/models/user/
# StackOverflow help with building Invoke-WebRequest cmdlet: https://stackoverflow.com/a/27951845/2382978

$ID       = 'CLIENT_ID'
$Secret   = 'CLIENT_SECRET'
$BaseUri  = 'https://www.udemy.com/api-2.0/'
$Query    = 'user/'
$FilePath = "$env:USERPROFILE\Desktop\Udemy.csv"

# Encode creds to Base-64
$EncodedCreds = [System.Convert]::ToBase64String( [System.Text.Encoding]::ASCII.GetBytes( $ID + ':' + $Secret ) )

$Params = @{
    Uri     = $BaseUri + $Query
    Method  = 'Post'
    Headers = @{
        Authorization = $EncodedCreds
    }
}

Invoke-WebRequest @Params

#$Response = Invoke-WebRequest @Params
#$Response | Export-Csv -Path $FilePath