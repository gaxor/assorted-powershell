Function Get-UserGroupMembershipByOU
{
    # Gets NTFS permissions (directories only), and saves to a CSV file
    Param
    (
	    [Parameter(Mandatory=$True)]
        $OUName, # Wildcards allowed
        $OutFile = "$PSScriptRoot\UserAccounts.csv"
    )

    $OUResult = Get-ADOrganizationalUnit -Filter { Name -like $OUName }

    If ( $OUResult -is [array] )
    {
        Write-Warning "Too many OUs match `"$OUName`""
        $OUResult | ForEach-Object { Write-Output "`t$($_.Name)" }
        Return
    }

    Get-ADUser -Filter * -SearchBase $OUResult.DistinguishedName -SearchScope Subtree | ForEach-Object {
        [PSCustomObject]@{
            Enabled     = $_.Enabled
            Name        = $_.GivenName, $_.Surname -join ' '
            AccountName = $($_.SamAccountName)
            MemberOf    = ( Get-ADPrincipalGroupMembership $_.DistinguishedName ).Name -join ';'
        }
    }
}
