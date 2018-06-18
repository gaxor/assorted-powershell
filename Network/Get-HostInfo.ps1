# Get host info
# Written by Gaxor December 2016
# This script is not complete
 
Param(
    [Parameter(Position=0,Mandatory=$True)]
    $ComputerName
)

Clear-Variable IP -ErrorAction SilentlyContinue
$ComputerName = $ComputerName.Trim()
$Ports2Check = @{
    ICMP  = $null
    RDP   = 3389
    SSH   = 22
    HTTP  = 80
    HTTPS = 443
}
$Check4Port = {
    Param(
    [Parameter(Position=0,Mandatory=$true)]
    $ComputerName,
    [Parameter(Position=1)]
    $Port,
    [Parameter(Position=2)]
    $InformationLevel = 'Quiet'
    )

    If($Port -eq $null){
        Test-NetConnection -ComputerName $ComputerName -InformationLevel $InformationLevel
    }
    Else{
        Test-NetConnection -ComputerName $ComputerName -Port $Port -InformationLevel $InformationLevel
    }
}

Function Approve-HostName{
    Try {
        Write-Output 'String-to-IP conversion'
        [IPAddress]$IP = $ComputerName
    }
    Catch [System.Management.Automation.RuntimeException]{
        Write-Output "$ComputerName is not an IP, resolving DNS"
        Try {
            [IPAddress]$IP = (Resolve-DnsName -Name $ComputerName -Type A -ErrorAction Stop)[0].IPAddress
        }
        Catch {
            Write-Output "ERROR: $($Error[0].Exception.Message)"
        }
    }
    Finally {
        [string]$IP = $IP.IPAddressToString
    }

    IF([string]::IsNullOrEmpty($IP)) {
        Write-Output "IP for `"$ComputerName`" not found. Stopping script."
        Return
    }
    Else {
        Write-Output "IP = $($IP)"
    }
}

Write-Output "Run the following jobs: $($Ports2Check.Keys)"
Foreach($Port in $Ports2Check.GetEnumerator()) {
    Start-Job -Name $Port.Name -ScriptBlock $Check4Port -ArgumentList $ComputerName,$Port.Value

}

$NetConStatus = @{}
Get-Job | Wait-Job
$NetConJobs = Get-Job | Select Id,Name
ForEach ($CurrentJob in $NetConJobs){
    $CurrentJobResult = Get-Job -Id $CurrentJob.Id | Receive-Job -Keep
    $NetConStatus.Add($CurrentJob.Name,$CurrentJobResult)
    Remove-Job -Id $CurrentJob.Id
}


<# ----- Host Info ----- #>

Write-Output "Query $ComputerName for host info"

$CPU = (Get-WmiObject -ComputerName $ComputerName win32_processor -Credential $Credential | Measure-Object -Property LoadPercentage -Average | Select Average).Average.tostring()
$Mem = Get-WmiObject -Class win32_operatingsystem -ComputerName $ComputerName | Select TotalVisibleMemorySize,FreePhysicalMemory,Caption,CSDVersion,OSArchitecture
 -Credential $Credential
 $Mem | Select-Object @{
    Name       = "MemUsage(MB)"; 
    Expression = {“{0:N2}” -f (($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)) / 1MB}
}
$MemPercent = (($Mem -as [int]) *100)/ $Mem.TotalVisibleMemorySize
$Vol = Get-WmiObject -Class win32_Volume -ComputerName $ComputerName -Filter "DriveLetter = 'C:'" -Credential $Credential | Select-object @{
    Name       = "C PercentFree"; 
    Expression = {“{0:N2}” -f  (($_.FreeSpace / $_.Capacity)*100)}
}
   
[PSCustomObject]$Stats = @{
    Server      = "$ComputerName"
    'CPU %'     = "$($CPU.Average)%"
    'MemFree'   = $Mem.'MemUsage(MB)'
    'Mem Used'  = ($Mem.'MemUsage(MB)' *100)/ $Mem.TotalVisibleMemorySize | Write-Output "$($Mem.'MemUsage(MB)')%"
    'Used C: %' = $Vol
    }
$Stats


<# ----- Host Info WMI TESTING ----- #>

$HostInfoWMI = Get-WmiObject -Class Win32_OperatingSystem | Select PSComputerName,TotalVisibleMemorySize,FreePhysicalMemory,Caption,ServicePackMajorVersion,Version,CSDVersion,OSArchitecture
$HostInfo = [Ordered]@{
    HostName          = $HostInfoWMI.PSComputerName
    OS                = $HostInfoWMI.Caption
    ServicePack       = $HostInfoWMI.CSDVersion
    OSVersion         = $HostInfoWMI.Version
    CPUType           = $HostInfoWMI.OSArchitecture
    'TotalMemory(GB)' = [System.Math]::Round($HostInfoWMI.TotalVisibleMemorySize / 1MB,2)
    'FreeMemory(GB)'  = [System.Math]::Round($HostInfoWMI.FreePhysicalMemory / 1MB,2)
}
$HostInfo

$memchip = wmic memorychip
(Get-CimInstance -ClassName 'Cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum
Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | Foreach {"{0:N0}" -f ([math]::round($_.Sum / 1MB))}

<# ----- Host Info Counter TESTING ----- #>

$Paths = (get-counter -listset memory).paths
Get-Counter -counter "\Memory\Cache Bytes"
(Get-Counter -counter $Paths[1]).CounterSamples | select CookedValue -Split(": ")