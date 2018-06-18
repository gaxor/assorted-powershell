Function Get-LocalGroupMembers
{
    Param
    (
        $ComputerName = $env:COMPUTERNAME,
        $OutPath = "$env:USERPROFILE\Desktop\$env:COMPUTERNAME.GroupMembers.csv"
    )

    $Groups = Get-WMIObject Win32_Group -Filter "LocalAccount='True'" | 
        Select-Object PSComputername,Name,@{Name="Members";Expression={$_.GetRelated("win32_useraccount").Name -join ";"} }
    $Groups | Export-Csv -Path $OutPath -NoTypeInformation
}
