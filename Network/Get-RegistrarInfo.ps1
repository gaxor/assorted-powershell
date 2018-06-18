<#
.Synopsis
   Returns domain registration info for the provided domain names (via text file).
.DESCRIPTION
   If Whois.exe does not exist in the same working directory, it will be downloaded from sysinternals.com and placed wherever the script is running.
.EXAMPLE
   Get-RegistrarInfo -FilePath C:\temp\domainlist.txt
.EXAMPLE
   Get-RegistrarInfo -FilePath C:\temp\domainlist.txt -DownloadDir C:\downloads\
#>
# Written by Greg Rowe (May 2017)

Param(
    [Parameter(Position=0,Mandatory=$True)]
    $FilePath
)

# Testing if whois.exe is here
$WhoisPath = Join-Path (Get-Location).ToString() 'whois.exe'
If(Test-Path $WhoisPath){}
Else{
    # Download whois.exe
    $URL = 'https://live.sysinternals.com/whois.exe'
    $WC  = New-Object System.Net.WebClient
    $WC.DownloadFile($URL, $WhoisPath)
}

$Domains = Get-Content -Path $FilePath
$AllDomainInfo = @()
$RegistrarValues = [ordered]@{
    Country     = 'Registrant Country:'
    Registrar   = 'Registrar:'
    NameServers = 'Name Server:'
    Email       = 'Registrant Email:'
    Updated     = 'Update'
    Created     = 'Creation Date:'
    Expires     = 'Expiration Date:'
    WHOISUpdate = 'update of WHOIS'
}

# Retrieve whois info, convert from wall-of-text to objects
ForEach ($Domain in $Domains){
    $Whois = whois $Domain | Where {$_.trim() -ne ''}
    $CurrDomainInfo = @{}
    ForEach ($Value in $RegistrarValues.GetEnumerator()){
        $CurrentValue = @()
        $CurrentValue = ($Whois | Select-String $Value.Value)
        If($Value.Key -eq 'NameServers'){
            Clear-Variable CurrValueOutput
            $CurrValueOutput = $CurrentValue | Where {$_ -ne $null} | ForEach{
                ($_.ToString()).Split(':',2)[1].Trim()
            }
        }
        ElseIf($Value.Value -like '*date*'){
            $CurrValueOutput = $CurrentValue[0].ToString().Split(':',2).Split('T')[1].Trim()
        }
        Else{
            $CurrValueOutput = $CurrentValue[0].ToString().Split(':',2)[1].Trim()
        }
        $CurrDomainInfo.Add($Value.Key,$CurrValueOutput)
    }
    $CurrentDomainObject = New-Object -TypeName PSObject -Property $CurrDomainInfo
    $CurrentDomainObject | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain
    $AllDomainInfo += $CurrentDomainObject
}

#Write-Output $AllDomainInfo
$AllDomainInfo | Format-Table -AutoSize -Property Domain,Registrar,Email,NameServers,Created,Expires,Updated,WHOISUpdate