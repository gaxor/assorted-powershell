Function Confirm-Connection
{
    # Tests TCP connection to website
    # Returns True if connection successful, False if not
    [CmdletBinding()]
    Param
    (
        [String] $Website,
        [Int] $Port
    )

    Write-Verbose "[ $Website ] [ Port:$Port ] Testing connection..."
    If ( ( Test-NetConnection $Website -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue ) -eq $True )
    {
        Write-Verbose "[ $Website ] [ Port:$Port ] Connection successful."
        Return $True
    }
    Else
    {
        Write-Warning "[ $Website ] [ Port:$Port ] Unable to connect."
        Return $False
    }
}

Function Get-DscCertificate
{
    # Gets certificate thumbprint for DSC MOF-encryption use
    # Returns thumbprint as a string
    [CmdletBinding()]
    Param
    (
        $ComputerName
    )

    $ScriptBlock  = {
        $DNSHostName = ( Get-WmiObject Win32_ComputerSystem ).DNSHostName
        Get-ChildItem -Path cert:\LocalMachine\My |
            Where {
                ( $_.FriendlyName -eq 'DSC Credential Encryption Certificate' ) `
                -and ( $_.Subject -eq "CN=$DNSHostName" ) `
                -and ( $_.NotAfter -gt ( Get-Date ) )
            }
    }
    $CommandParameters = @{
        ComputerName = $ComputerName
        ScriptBlock  = $ScriptBlock
    }
    
    If ( $ComputerName -eq $Null -or $ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost' )
    {
        $CommandParameters.Remove( 'ComputerName' )
    }

    Try
    {
        Invoke-Command @CommandParameters -ErrorAction Stop
    }
    Catch
    {
        Write-Warning "[ Node:$ComputerName ] [ DscCertificate ] $( $Error[0].Exception.Message )"
    }
}

Function Get-Powershell5InstallState
{
    # Tests if Powershell 5 is installed
    # Returns True if installed, False if not
    [CmdletBinding()]
    Param()

    Try
    {
        Write-Verbose '[ Powershell ] Test for version 5'

        # Try triggering a "command not found" failure, as this cmdlet is new to Powershell 5.1
        Get-PackageProvider | Out-Null
        Write-Verbose "[ Powershell ] $( $PSVersionTable.PSVersion.Major ).$( $PSVersionTable.PSVersion.Minor )"
        Return $True
    }
    Catch
    {
        Write-Verbose "[ Powershell ] $( $PSVersionTable.PSVersion.Major ).$( $PSVersionTable.PSVersion.Minor )"
        Return $False
    }
}

Function Get-WebFile
{
    # Downloads file from the web
    # Returns full path of downloaded file as a string, returns False if download fails
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        [Alias( 'Url' )]
        $Uri,
        $Path
    )

    If ( -not $Path )
    {
        $Path = $PSScriptRoot
        Write-Verbose "Setting download path to $Path"
    }

    $FileName    = Split-Path $Uri -Leaf
    $Destination = Join-Path $Path $FileName
    
    # Ensure destination path is present
    New-Item $Path -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    If ( ( Test-Path $Path ) -eq $False )
    {
        Write-Warning "[ Download ] [ $FileName ] Path: $Destination is not valid"
        Return $False
    }
    Else
    {
        # Delete file if it already exists (possibly a previous/aborted download)
        Remove-Item $Destination -ErrorAction SilentlyContinue

        # Download file
        Write-Verbose "[ Download ] [ $FileName ] Downloading..."
        ( New-Object System.Net.WebClient ).DownloadFile( $Uri, $Destination )

        # Output full path of downloaded file
        Return $Destination
    }
}

Function Install-DscCertificate
{
    # Installs self-signed certificate for DSC MOF-encryption use
    # Returns X509Certificate2 object (after creating it and saving to LocalMachine Store)
    [CmdletBinding()]
    Param
    (
        $ComputerName = ( Get-WmiObject Win32_ComputerSystem ).DNSHostName,
        $OutputPath
    )

    $ScriptBlock = {
        [CmdletBinding()]
        Param
        (
            $OutputPath
        )
        Function New-SelfSignedCertificateEx
        {
            # Author: Vadims Podans
            # Source: https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6
            [OutputType('[System.Security.Cryptography.X509Certificates.X509Certificate2]')]
            [CmdletBinding(DefaultParameterSetName = '__store')]
                param (
                    [Parameter(Mandatory = $true, Position = 0)]
                    [string]$Subject,
                    [Parameter(Position = 1)]
                    [datetime]$NotBefore = [DateTime]::Now.AddDays(-1),
                    [Parameter(Position = 2)]
                    [datetime]$NotAfter = $NotBefore.AddDays(365),
                    [string]$SerialNumber,
                    [Alias('CSP')]
                    [string]$ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0",
                    [string]$AlgorithmName = "RSA",
                    [int]$KeyLength = 2048,
                    [validateSet("Exchange","Signature")]
                    [string]$KeySpec = "Exchange",
                    [Alias('EKU')]
                    [Security.Cryptography.Oid[]]$EnhancedKeyUsage,
                    [Alias('KU')]
                    [Security.Cryptography.X509Certificates.X509KeyUsageFlags]$KeyUsage,
                    [Alias('SAN')]
                    [String[]]$SubjectAlternativeName,
                    [bool]$IsCA,
                    [int]$PathLength = -1,
                    [Security.Cryptography.X509Certificates.X509ExtensionCollection]$CustomExtension,
                    [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')]
                    [string]$SignatureAlgorithm = "SHA1",
                    [string]$FriendlyName,
                    [Parameter(ParameterSetName = '__store')]
                    [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "CurrentUser",
                    [Parameter(Mandatory = $true, ParameterSetName = '__file')]
                    [Alias('OutFile','OutPath','Out')]
                    [IO.FileInfo]$Path,
                    [Parameter(Mandatory = $true, ParameterSetName = '__file')]
                    [Security.SecureString]$Password,
                    [switch]$AllowSMIME,
                    [switch]$Exportable
                )
                $ErrorActionPreference = "Stop"
                if ([Environment]::OSVersion.Version.Major -lt 6) {
                    $NotSupported = New-Object NotSupportedException -ArgumentList "Windows XP and Windows Server 2003 are not supported!"
                    throw $NotSupported
                }
                $ExtensionsToAdd = @()

            #region constants
                # contexts
                New-Variable -Name UserContext -Value 0x1 -Option Constant
                New-Variable -Name MachineContext -Value 0x2 -Option Constant
                # encoding
                New-Variable -Name Base64Header -Value 0x0 -Option Constant
                New-Variable -Name Base64 -Value 0x1 -Option Constant
                New-Variable -Name Binary -Value 0x3 -Option Constant
                New-Variable -Name Base64RequestHeader -Value 0x4 -Option Constant
                # SANs
                New-Variable -Name OtherName -Value 0x1 -Option Constant
                New-Variable -Name RFC822Name -Value 0x2 -Option Constant
                New-Variable -Name DNSName -Value 0x3 -Option Constant
                New-Variable -Name DirectoryName -Value 0x5 -Option Constant
                New-Variable -Name URL -Value 0x7 -Option Constant
                New-Variable -Name IPAddress -Value 0x8 -Option Constant
                New-Variable -Name RegisteredID -Value 0x9 -Option Constant
                New-Variable -Name Guid -Value 0xa -Option Constant
                New-Variable -Name UPN -Value 0xb -Option Constant
                # installation options
                New-Variable -Name AllowNone -Value 0x0 -Option Constant
                New-Variable -Name AllowNoOutstandingRequest -Value 0x1 -Option Constant
                New-Variable -Name AllowUntrustedCertificate -Value 0x2 -Option Constant
                New-Variable -Name AllowUntrustedRoot -Value 0x4 -Option Constant
                # PFX export options
                New-Variable -Name PFXExportEEOnly -Value 0x0 -Option Constant
                New-Variable -Name PFXExportChainNoRoot -Value 0x1 -Option Constant
                New-Variable -Name PFXExportChainWithRoot -Value 0x2 -Option Constant
            #endregion

            #region Subject processing
                # http://msdn.microsoft.com/en-us/library/aa377051(VS.85).aspx
                $SubjectDN = New-Object -ComObject X509Enrollment.CX500DistinguishedName
                $SubjectDN.Encode($Subject, 0x0)
            #endregion

            #region Enhanced Key Usages processing
                if ($EnhancedKeyUsage) {
                    $OIDs = New-Object -ComObject X509Enrollment.CObjectIDs
                    $EnhancedKeyUsage | ForEach-Object {
                        $OID = New-Object -ComObject X509Enrollment.CObjectID
                        $OID.InitializeFromValue($_.Value)
                        # http://msdn.microsoft.com/en-us/library/aa376785(VS.85).aspx
                        $OIDs.Add($OID)
                    }
                    # http://msdn.microsoft.com/en-us/library/aa378132(VS.85).aspx
                    $EKU = New-Object -ComObject X509Enrollment.CX509ExtensionEnhancedKeyUsage
                    $EKU.InitializeEncode($OIDs)
                    $ExtensionsToAdd += "EKU"
                }
            #endregion

            #region Key Usages processing
                if ($KeyUsage -ne $null) {
                    $KU = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
                    $KU.InitializeEncode([int]$KeyUsage)
                    $KU.Critical = $true
                    $ExtensionsToAdd += "KU"
                }
            #endregion

            #region Basic Constraints processing
                if ($PSBoundParameters.Keys.Contains("IsCA")) {
                    # http://msdn.microsoft.com/en-us/library/aa378108(v=vs.85).aspx
                    $BasicConstraints = New-Object -ComObject X509Enrollment.CX509ExtensionBasicConstraints
                    if (!$IsCA) {$PathLength = -1}
                    $BasicConstraints.InitializeEncode($IsCA,$PathLength)
                    $BasicConstraints.Critical = $IsCA
                    $ExtensionsToAdd += "BasicConstraints"
                }
            #endregion

            #region SAN processing
                if ($SubjectAlternativeName) {
                    $SAN = New-Object -ComObject X509Enrollment.CX509ExtensionAlternativeNames
                    $Names = New-Object -ComObject X509Enrollment.CAlternativeNames
                    foreach ($altname in $SubjectAlternativeName) {
                        $Name = New-Object -ComObject X509Enrollment.CAlternativeName
                        if ($altname.Contains("@")) {
                            $Name.InitializeFromString($RFC822Name,$altname)
                        } else {
                            try {
                                $Bytes = [Net.IPAddress]::Parse($altname).GetAddressBytes()
                                $Name.InitializeFromRawData($IPAddress,$Base64,[Convert]::ToBase64String($Bytes))
                            } catch {
                                try {
                                    $Bytes = [Guid]::Parse($altname).ToByteArray()
                                    $Name.InitializeFromRawData($Guid,$Base64,[Convert]::ToBase64String($Bytes))
                                } catch {
                                    try {
                                        $Bytes = ([Security.Cryptography.X509Certificates.X500DistinguishedName]$altname).RawData
                                        $Name.InitializeFromRawData($DirectoryName,$Base64,[Convert]::ToBase64String($Bytes))
                                    } catch {$Name.InitializeFromString($DNSName,$altname)}
                                }
                            }
                        }
                        $Names.Add($Name)
                    }
                    $SAN.InitializeEncode($Names)
                    $ExtensionsToAdd += "SAN"
                }
            #endregion

            #region Custom Extensions
                if ($CustomExtension) {
                    $count = 0
                    foreach ($ext in $CustomExtension) {
                        # http://msdn.microsoft.com/en-us/library/aa378077(v=vs.85).aspx
                        $Extension = New-Object -ComObject X509Enrollment.CX509Extension
                        $EOID = New-Object -ComObject X509Enrollment.CObjectId
                        $EOID.InitializeFromValue($ext.Oid.Value)
                        $EValue = [Convert]::ToBase64String($ext.RawData)
                        $Extension.Initialize($EOID,$Base64,$EValue)
                        $Extension.Critical = $ext.Critical
                        New-Variable -Name ("ext" + $count) -Value $Extension
                        $ExtensionsToAdd += ("ext" + $count)
                        $count++
                    }
                }
            #endregion

            #region Private Key
                # http://msdn.microsoft.com/en-us/library/aa378921(VS.85).aspx
                $PrivateKey = New-Object -ComObject X509Enrollment.CX509PrivateKey
                $PrivateKey.ProviderName = $ProviderName
                $AlgID = New-Object -ComObject X509Enrollment.CObjectId
                $AlgID.InitializeFromValue(([Security.Cryptography.Oid]$AlgorithmName).Value)
                $PrivateKey.Algorithm = $AlgID
                # http://msdn.microsoft.com/en-us/library/aa379409(VS.85).aspx
                $PrivateKey.KeySpec = switch ($KeySpec) {"Exchange" {1}; "Signature" {2}}
                $PrivateKey.Length = $KeyLength
                # key will be stored in current user certificate store
                switch ($PSCmdlet.ParameterSetName) {
                    '__store' {
                        $PrivateKey.MachineContext = if ($StoreLocation -eq "LocalMachine") {$true} else {$false}
                    }
                    '__file' {
                        $PrivateKey.MachineContext = $false
                    }
                }
                $PrivateKey.ExportPolicy = if ($Exportable) {1} else {0}
                $PrivateKey.Create()
            #endregion

                # http://msdn.microsoft.com/en-us/library/aa377124(VS.85).aspx
                $Cert = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
                if ($PrivateKey.MachineContext) {
                    $Cert.InitializeFromPrivateKey($MachineContext,$PrivateKey,"")
                } else {
                    $Cert.InitializeFromPrivateKey($UserContext,$PrivateKey,"")
                }
                $Cert.Subject = $SubjectDN
                $Cert.Issuer = $Cert.Subject
                $Cert.NotBefore = $NotBefore
                $Cert.NotAfter = $NotAfter
                foreach ($item in $ExtensionsToAdd) {$Cert.X509Extensions.Add((Get-Variable -Name $item -ValueOnly))}
                if (![string]::IsNullOrEmpty($SerialNumber)) {
                    if ($SerialNumber -match "[^0-9a-fA-F]") {throw "Invalid serial number specified."}
                    if ($SerialNumber.Length % 2) {$SerialNumber = "0" + $SerialNumber}
                    $Bytes = $SerialNumber -split "(.{2})" | Where-Object {$_} | ForEach-Object{[Convert]::ToByte($_,16)}
                    $ByteString = [Convert]::ToBase64String($Bytes)
                    $Cert.SerialNumber.InvokeSet($ByteString,1)
                }
                if ($AllowSMIME) {$Cert.SmimeCapabilities = $true}
                $SigOID = New-Object -ComObject X509Enrollment.CObjectId
                $SigOID.InitializeFromValue(([Security.Cryptography.Oid]$SignatureAlgorithm).Value)
                $Cert.SignatureInformation.HashAlgorithm = $SigOID
                # completing certificate request template building
                $Cert.Encode()

                # interface: http://msdn.microsoft.com/en-us/library/aa377809(VS.85).aspx
                $Request = New-Object -ComObject X509Enrollment.CX509enrollment
                $Request.InitializeFromRequest($Cert)
                $Request.CertificateFriendlyName = $FriendlyName
                $endCert = $Request.CreateRequest($Base64)
                $Request.InstallResponse($AllowUntrustedCertificate,$endCert,$Base64,"")
                switch ($PSCmdlet.ParameterSetName) {
                    '__file' {
                        $PFXString = $Request.CreatePFX(
                            [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)),
                            $PFXExportEEOnly,
                            $Base64
                        )
                        Set-Content -Path $Path -Value ([Convert]::FromBase64String($PFXString)) -Encoding Byte
                    }
                }
                [Byte[]]$CertBytes = [Convert]::FromBase64String($endCert)
                New-Object Security.Cryptography.X509Certificates.X509Certificate2 @(,$CertBytes)
        }

        $DNSHostName          = ( Get-WmiObject Win32_ComputerSystem ).DNSHostName
        $SelfSignedCertParams = @{
            Subject            = "CN=$DNSHostName"
            EKU                = 'Document Encryption'
            KeyUsage           = 'KeyEncipherment, DataEncipherment'
            SAN                = $DNSHostName
            FriendlyName       = 'DSC Credential Encryption Certificate'
            Exportable         = $True
            StoreLocation      = 'LocalMachine'
            KeyLength          = 2048
            ProviderName       = 'Microsoft Enhanced Cryptographic Provider v1.0'
            AlgorithmName      = 'RSA'
            SignatureAlgorithm = 'SHA256'
            NotAfter           = ( [DateTime]::Now.AddYears( 50 ) )
        }

        If ( $OutputPath )
        {
            $SelfSignedCertParams.Add( @{ 'Path' = $OutputPath } )
        }

        New-SelfsignedCertificateEx @SelfSignedCertParams
    }
    $CommandParameters = @{
        ComputerName = $ComputerName
        ScriptBlock  = $ScriptBlock
    }

    If ( $OutputPath )
    {
        $CommandParameters.Add( @{ 'ArgumentList' = $OutputPath } )
    }

    If ( $ComputerName -eq $Null -or $ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost' )
    {
        $CommandParameters.Remove( 'ComputerName' )
    }

    Try
    {
        Invoke-Command @CommandParameters -ErrorAction Stop
    }
    Catch
    {
        Write-Warning "[ Node:$ComputerName ] [ DSCCertificateInstall ] $( $Error[0].Exception.Message )"
    }
}

Function Install-DscFeature
{
    # Installs DSC (Windows feature) on target computer
    # Returns True once installed, False if install fails
    [CmdletBinding()]
    Param
    (
        $ComputerName
    )

    $ScriptBlock  = {
        Write-Verbose '[ DSCFeature ] Get Insatllation State...'
        If ( ( Get-WindowsFeature -Name DSC-Service ).InstallState -EQ 'Installed' )
        {
            Write-Verbose '[ DSCFeature ] State: Installed'
            Return $True
        }
        Else
        {
            Try
            {
                Write-Verbose '[ DSCFeature ] Installing...'
                Install-WindowsFeature -Name DSC-Service
                Write-Verbose '[ DSCFeature ] Installation successful'
                Return $True
            }
            Catch [System.Management.Automation.CommandNotFoundException]
            {
                Try
                {
                    # This method has thrown errors in some 2008R2 environments; added testing advised.
                    Write-Verbose '[ DSCFeature ] Installation failed; Try older method...'
                    Add-WindowsFeature -Name DSC-Service
                    & DISM /Online /Enable-Feature /FeatureName:DSC-Service
                    Write-Verbose '[ DSCFeature ] Installation successful'
                    Return $True
                }
                Catch
                {
                    Write-Warning "[ DSCFeature ] $( $Error[0].Exception.Message )"
                    Return $False
                }
            }
            Catch
            {
                Write-Warning "[ DSCFeature ] $( $Error[0].Exception.Message )"
                Return $False
            }
        }
    }
    $CommandParameters = @{
        ComputerName = $ComputerName
        ScriptBlock  = $ScriptBlock
    }
    
    If ( $ComputerName -eq $Null -or $ComputerName -like $env:COMPUTERNAME -or $ComputerName -eq 'localhost' )
    {
        $CommandParameters.Remove( 'ComputerName' )
    }

    Try
    {
        $Result = Invoke-Command @CommandParameters -ErrorAction Stop
    }
    Catch
    {
        Write-Warning "[ Node:$ComputerName ] [ DSCFeature ] $( $Error[0].Exception.Message )"
    }

    Return $Result
}

Function Install-DscModule
{
    # Installs DSC resource
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        [String] $Module,
        [String] $Version
    )

    If ( $Version )
    {
        Try
        {
            [Array] $Ver = (Get-DscResource -Module $Module -WarningAction Stop).Version | ForEach { $_.ToString().trim('.0') }
        }
        Catch{}
    }

    If ( ( $Ver -ne $Null ) -and ( $Ver -contains $Version.trim('.0') ) )
    {
        Write-Verbose "[ PackageManager ] [ $Module ] State: Installed"
    }
    Else
    {
        Try
        {
            $Params = @{
                Name           = $Module
                MaximumVersion = $Version
                Force          = $True
            }
            Write-Verbose "[ PackageManager ] [ $Module ] Installing..."
            Install-Module @Params
            Write-Verbose "[ PackageManager ] [ $Module ] Installation successful"
        }
        Catch
        {
            Write-Warning "[ PackageManager ] [ $Module ] install failed:"
            Write-Warning "[ PackageManager ] [ $Module ] $( $Error[0].Exception.Message )"
        }
    }
}

Function Install-NuGet
{
    [CmdletBinding()]
    Param()

    # Installs NuGet PackageManager (is used in conjunction with PowerShell Gallery)
    Write-Verbose '[ PackageManager ] [ NuGet ] Get install state...'
    If ( ( Get-PackageProvider ).Name -Contains 'NuGet' )
    {
        Write-Verbose '[ PackageManager ] [ NuGet ] State: Installed'
    }
    Else
    {
        # Test web connectivity for downloading NuGet
        [System.Collections.ArrayList] $Connection = @()
        $Connection.Add( ( Confirm-Connection -Website 'go.microsoft.com' -Port 443 ) ) | Out-Null
        $Connection.Add( ( Confirm-Connection -Website 'oneget.org' -Port 443 ) ) | Out-Null

        If ( $Connection -contains $False )
        {
            Write-Warning '[ PackageManager ] [ NuGet ] Unable to install. Ensure go.microsoft.com and oneget.org are accessible via HTTPS.'
            Return
        }

        Write-Verbose '[ PackageManager ] [ NuGet ] Installing...'
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Write-Verbose '[ PackageManager ] [ NuGet ] Installation successful'
    }
}

Function Import-Variables
{
    # Imports variables from a Powershell file
    [CmdletBinding()]
    Param
    (
        [String] $FilePath
    )

    Invoke-Expression ( Get-Content $FilePath | Out-String )

    # Get the command name
    $CommandName = $PSCmdlet.MyInvocation.InvocationName
    
    # Get the list of parameters for the command
    $ParameterList = ( Get-Command -Name $CommandName ).Parameters

    # Grab each parameter value, using Get-Variable
    ForEach ( $Parameter in $ParameterList )
    {
        Get-Variable -Name $ParameterList
    }
}

Function Set-ConsoleColors
{
    # Sets foreground and background console colors
    Param
    (
        $VerboseColor = 'Cyan',
        $WarningColor = 'Yellow',
        $ErrorColor   = 'Red'
    )
    
    # Set event background to match current console background
    Switch( $Host.Name )
    {
        'ConsoleHost'
        {
            $Host.PrivateData.VerboseBackgroundColor = $Host.UI.RawUI.BackgroundColor
            $Host.PrivateData.WarningBackgroundColor = $Host.UI.RawUI.BackgroundColor
            $Host.PrivateData.ErrorBackgroundColor   = $Host.UI.RawUI.BackgroundColor
        }
        'Windows PowerShell ISE Host'
        {
            $Host.PrivateData.VerboseBackgroundColor = $Host.PrivateData.ConsolePaneBackgroundColor
            $Host.PrivateData.WarningBackgroundColor = $Host.PrivateData.ConsolePaneBackgroundColor
            $Host.PrivateData.ErrorBackgroundColor   = $Host.PrivateData.ConsolePaneBackgroundColor
        }
    }

    # Set event foreground colors
    $Host.PrivateData.VerboseForegroundColor = $VerboseColor
    $Host.PrivateData.WarningForegroundColor = $WarningColor
    $Host.PrivateData.ErrorForegroundColor   = $ErrorColor
}

Function Set-PsGalleryTrust
{
    # Sets the trust level for PowerShell Gallery PackageManager
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory )]
        [ValidateSet( 'Trusted','UnTrusted' )]
        $Policy
    )
    If ( ( Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue ).InstallationPolicy -EQ $Policy )
    {
        Write-Verbose "[ PackageManager ] [ PSGallery ] is $Policy"
    }
    Else
    {
        Write-Verbose "[ PackageManager ] [ PSGallery ] Set trust level to $Policy"
        Set-PSRepository -Name PSGallery -InstallationPolicy $Policy
    }
}

Function Set-TempExecPolicy
{
    # Sets execution policy for all scopes
    # Begin - Set all scopes to Unrestricted
    # End   - Set all scopes back to previous policy if possible
    # Previous policy is stored in the 'Script' scope
    [CmdletBinding()]
    Param
    (
        # Mutually exclusive switch parameter sets: Begin or End
        [CmdletBinding( DefaultParameterSetName = 'Begin' )]
        [Parameter( ParameterSetName = 'Begin' )]
        [Switch] $Begin,
        
        [Parameter( ParameterSetName = 'End' )]
        [Switch] $End
    )
    
    If ( $Begin )
    {
        $Script:OriginalExecPolicy = Get-ExecutionPolicy -List | Where { $_.Scope -NotLike '*Policy'  }
        $Script:OriginalExecPolicy | ForEach {
            If ( $_.ExecutionPolicy -NE 'Unrestricted' )
            {
                Write-Verbose "[ ExecutionPolicy ] [ Scope:$( $_.Scope ) ] Set $( $_.ExecutionPolicy ) to Unrestricted"
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope $_.Scope -Force
            }
        }
    }

    If ( $End )
    {
        Write-Verbose "[ ExecutionPolicy ] Reverting to initially observed settings..."
        If ( $Script:OriginalExecPolicy )
        {
            $Script:OriginalExecPolicy | ForEach {
                If ( $_.ExecutionPolicy -EQ 'Unrestricted' )
                {
                    Write-Verbose "[ ExecutionPolicy ] [ Scope:$( $_.Scope ) ] Set Unrestricted to $( $_.ExecutionPolicy )"
                    Set-ExecutionPolicy -ExecutionPolicy $_.ExecutionPolicy -Scope $_.Scope -Force
                }
            }
        }
        Else
        {
            Write-Verbose "[ ExecutionPolicy ] Initial policy not found"
        }
    }
}

Function Uninstall-DeprecatedModule
{
    # Uninstalls old versions of a Powershell module if a newer version is installed
    # If a version is specified, uninstall all other installed versions
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True,
                    ValueFromPipelineByPropertyName = $True )]
        [Alias( 'Module' )]
        [String] $Name,
        [Alias( 'DesiredVersion' )]
        [String] $Version
    )

    Begin {}
    Process
    {
        Write-Verbose "[ PackageManager ] [ $Name ] Check for old versions..."
        $Installed  = Get-InstalledModule $Name -AllVersions
        If ( $Version )
        {
            $Deprecated = $Installed | Where { $_.Version.ToString().Trim('.0') -ne $Version.Trim('.0') }
        }
        Else
        {
            $Latest     = $Installed | Sort | Select -First 1
            $Deprecated = $Installed | Where { $_.Version -ne $Latest.Version }
        }

        If ( $Deprecated )
        {
            $Deprecated | ForEach {
                Write-Verbose "[ PackageManager ] [ $Name ] Remove version $($_.Version )..."
                $Deprecated | Uninstall-Module
            }
        }
    }
    End {}
}

Function Rename-SitecoreAdminFiles
{
    # Renames Sitecore admin files
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        [Alias( 'Website' )]
        $Path,
        $Suffix = ".disabled",
        $FileNames = @(
            'Cache.aspx'
            'DBCleanup.aspx'
            'dbbrowser.aspx'
            'ShowServicesConfig.aspx'
            'eventqueuestats.aspx'
            'FillDB.aspx'
            'InstallLanguage.aspx'
            'Jobs.aspx'
            'LinqScratchPad.aspx'
            'Logs.aspx'
            'MediaHash.aspx'
            'PackageItem.aspx'
            'PathAnalyzer.aspx'
            'Pipelines.aspx'
            'PublishQueueStats.aspx'
            'RawSearch.aspx'
            'RebuildKeyBehaviorCache.aspx'
            'RebuildReportingDB.aspx'
            'RedeployMarketingData.aspx'
            'RemoveBrokenLinks.aspx'
            'restore.aspx'
            'SecurityTools.aspx'
            'serialization.aspx'
            'SetSACEndpoint.aspx'
            'ShowConfig.aspx'
            'SqlShell.aspx'
            'stats.aspx'
            'unlock_admin.aspx'
        )
    )

    $AllFiles = Get-ChildItem -File -Path $Path
    $FilesToUpdate = $AllFiles | Where { $_.Name -in $FileNames }
    $FilesToUpdate | ForEach { Rename-Item -Path $_.FullName -NewName "$($_.Name)$Suffix" }
}

Function Restrict-HttpMethods
{
    # Renames Sitecore admin files
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        [Alias( 'Path' )]
        $Website,
        [Alias( 'Methods' )]
        $HttpMethods = @('GET', 'POST', 'PUT', 'DELETE', 'OPTIONS')
    )

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
}

Function Remove-UnwantedFolders
{
    # 
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        $WebsiteRoot,
        $ItemsToRemove = @(
            '/sitecore/content/Global/My Profile'
            '/sitecore/content/Global/Global Repository'
            '/sitecore/content/Global/Terms and Conditions'
            '/sitecore/content/Global/Global Repository'
            '/sitecore/content/Global/Configuration/TermsAndConditions'
            '/sitecore/content/Global/Configuration/Foundation/Company/TermsAndConditions'
            '/sitecore/content/Global/Configuration/Foundation/Company/Validators'
            '/sitecore/templates/Foundation/Company/_TermsAndConditions'
            '/sitecore/templates/Foundation/Company/Site Repository'
        )
    )

    $ItemsToRemove | ForEach { Remove-Item ( Join-Path $WebsiteRoot $_ ) -Recurse -Force -WhatIf }
}

Function Restrict-IPRange
{
    # Renames Sitecore admin files
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $True )]
        [Alias( 'Path' )]
        $Website,
        [Parameter( Mandatory = $True )]
        $IPAddress,
        $SubnetMask
    )

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
}
