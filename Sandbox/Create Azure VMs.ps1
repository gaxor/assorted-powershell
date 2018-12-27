Add-AzureAccount
	
New-AzureStorageAccount –StorageAccountName '150west' -Location 'West US'

Get-AzureSubscription
Set-AzureSubscription -SubscriptionName '150dollar' -CurrentStorageAccountName '150west'

Get-AzureVMImage | Select-Object -Property ImageFamily, ImageName, PublishedDate | Where-Object { $_.ImageFamily -like 'Windows Server 2012 R2*' } | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Format-List


$image = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20151022-en.us-127GB.vhd'
$vmname = 'dc1'
$vmsize = 'Small'
<# vm sizes:
ExtraSmall
Small
Medium
Large
ExtraLarge
A5
A6
A7
A8
A9
Basic_A0
Basic_A1
Basic_A2
Basic_A3
Basic_A4
Standard_D1
Standard_D2
Standard_D3
Standard_D4
Standard_D11
Standard_D12
Standard_D13
Standard_D14
#>

$vm1 = New-AzureVMConfig -ImageName $image -Name $vmname -InstanceSize $vmsize

$cred = Get-Credential -Message 'Type the local administrator account username and password:'

$vm1 | Add-AzureProvisioningConfig -Windows -AdminUsername $cred.GetNetworkCredential().Username -Password $cred.GetNetworkCredential().Password

$svcname='west150service'
New-AzureService -ServiceName $svcname -Label 'My label' -Location 'West US'
New-AzureVM –ServiceName $svcname -VMs $vm1 -WaitForBoot

Get-AzureVM
