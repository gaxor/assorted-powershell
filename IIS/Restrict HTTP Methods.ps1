$Website = "domain.tld"
$HttpMethods = @('GET', 'POST', 'PUT', 'DELETE')

# Set http methods 'allowUnlisted' to false
$VerbAllowUnlisted = @{
    Name   = 'allowUnlisted'
    PSPath = "IIS:\Sites\$Website"
    Filter = 'system.webServer/security/requestFiltering/verbs'
}

If ( ( Get-WebConfigurationProperty @VerbAllowUnlisted ).Value -eq $True )
{
    Write-Verbose 'VerbAllowUnlisted is True'
}
Else
{
    Write-Verbose "Set - allowUnlisted"
    Set-WebConfigurationProperty @VerbAllowUnlisted -Value $False -Verbose
}

# Add allowed verbs
$VerbsProperties = @{
    PSPath  = "IIS:\Sites\$Website"
    Filter  = 'system.webServer/security/requestFiltering'
    Name    = 'Verbs'
}

ForEach ( $Method in $HttpMethods )
{
    $MethodsProperties = @{
        PSPath  = "IIS:\Sites\$Website"
        Filter  = 'system.webServer/security/requestFiltering/verbs'
        Name    = $Method
    }
    If ( ( Get-WebConfigurationProperty @MethodsProperties ).Value -eq $True )
    {
        Write-Verbose 'Verb AllowUnlisted is True'
    }
    Else
    {
        Try
        {
            Write-Verbose "ADD - $Method"
            Add-WebConfigurationProperty @VerbsProperties -Value @{ VERB = $Method; allowed = 'True' }
        }
        Catch
        {
            Write-Verbose "SET - $Method"
            Set-WebConfigurationProperty @VerbsProperties -Value @{ VERB = $Method; allowed = 'True' }
        }
    }
}
