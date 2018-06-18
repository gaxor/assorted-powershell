# Requires Azure Powershell: https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-4.4.1#step-1-install-powershellget
# Switches the network interfaces between two Azure VMs
# WARNING: This will stop the VMs!
# WARNING: This does not work as I had expected; the VMs lose the public IPs permanently.

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [String] $VMName1,
    [Parameter(Mandatory=$True)]
    [String] $VMName2,
    [String] $ResourceGroup,
    [String] $VirtualNetwork,
    [String] $SubnetName,
    [String] $Region
)

# Log into Azure Powershell
#Login-AzureRmAccount

# Get subnet
Write-Verbose "Getting subnet info for $SubnetName..."
$VNet = Get-AzureRmVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $ResourceGroup
$Subnet = $VNet.Subnets | Where {$_.Name -eq $SubnetName}

$NewNicParams = @{
    ResourceGroupName = $ResourceGroup
    Location          = $Region
    Subnet            = $Subnet
}

# Get VM info
Write-Verbose "Getting VM info for $VMName1..."
$VM1 = Get-AzureRmVM -Name $VMName1 -ResourceGroupName $ResourceGroup
Write-Verbose "Creating temporary NIC for $VMName1..."
$VM1Data = @{
    Name    = $VMName1
    Nic     = $VM1.NetworkProfile.NetworkInterfaces.id
    TempNic = (New-AzureRmNetworkInterface @NewNicParams -Name "TEMPNIC-$([guid]::NewGuid().Guid.Split('-')[-1])").id
}

Write-Verbose "Getting VM info for $VMName2..."
$VM2 = Get-AzureRmVM -Name $VMName2 -ResourceGroupName $ResourceGroup
Write-Verbose "Creating temporary NIC for $VMName2..."
$VM2Data = @{
    Name    = $VMName2
    Nic     = $VM2.NetworkProfile.NetworkInterfaces.id
    TempNic = (New-AzureRmNetworkInterface @NewNicParams -Name "TEMPNIC-$([guid]::NewGuid().Guid.Split('-')[-1])").id
}

# Stop VMs
Write-Verbose "Stopping $($VM1.Name)..."
Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName1 -Force
Write-Verbose "Stopping $($VM2.Name)..."
Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName2 -Force

# Add temporary NICs to VMs (Azure VMs need at least 1 NIC present at all times)
Write-Verbose "Adding temporary NIC to $($VM1.Name)..."
Add-AzureRmVMNetworkInterface -VM $VM1 -Id $VM1Data.TempNic -Primary
Write-Verbose "Adding temporary NIC to $($VM2.Name)..."
Add-AzureRmVMNetworkInterface -VM $VM2 -Id $VM2Data.TempNic -Primary

# Remove original NICs
Write-Verbose "Removing original NIC from $($VM1.Name)..."
Remove-AzureRmVMNetworkInterface -VM $VM1 -NetworkInterfaceIDs $VM1Data.Nic
Write-Verbose "Removing original NIC from $($VM2.Name)..."
Remove-AzureRmVMNetworkInterface -VM $VM2 -NetworkInterfaceIDs $VM2Data.Nic

# Update the VM state in Azure
Write-Verbose "Updating computer settings in Azure for $($VM1.Name)..."
Update-AzureRmVM -VM $VM1 -ResourceGroupName $ResourceGroup
Write-Verbose "Updating computer settings in Azure for $($VM2.Name)..."
Update-AzureRmVM -VM $VM2 -ResourceGroupName $ResourceGroup

# Swap NICs
Add-AzureRmVMNetworkInterface -VM $VM1 -Id $VM2Data.Nic -Primary
Add-AzureRmVMNetworkInterface -VM $VM2 -Id $VM1Data.Nic -Primary

# Remove temporary NICs
Write-Verbose "Removing temporary NIC from $($VM1.Name)..."
Remove-AzureRmVMNetworkInterface -VM $VM1 -NetworkInterfaceIDs $VM1Data.TempNic
Write-Verbose "Removing temporary NIC from $($VM2.Name)..."
Remove-AzureRmVMNetworkInterface -VM $VM2 -NetworkInterfaceIDs $VM2Data.TempNic

# Update the VM state in Azure
Write-Verbose "Updating computer settings in Azure for $($VM1.Name)..."
Update-AzureRmVM -VM $VM1 -ResourceGroupName $ResourceGroup
Write-Verbose "Updating computer settings in Azure for $($VM2.Name)..."
Update-AzureRmVM -VM $VM2 -ResourceGroupName $ResourceGroup

# Start VMs
Write-Verbose "Starting $($VM1.Name)..."
Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName1
Write-Verbose "Starting $($VM2.Name)..."
Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName2

# Delete temporary NICs
Write-Verbose "Deleting temporary NICs..."
Remove-AzureRmNetworkInterface -Name $VM1Data.TempNic.Split('/')[-1] -ResourceGroupName $ResourceGroup -Force
Remove-AzureRmNetworkInterface -Name $VM2Data.TempNic.Split('/')[-1] -ResourceGroupName $ResourceGroup -Force
