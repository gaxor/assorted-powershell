Function Get-NTFSAudit
{
    # Writes NTFS permissions to a CSV file (directories only)
    Param
    (
	    [Parameter(Mandatory=$True)]
        $RootPath,
        $OutFile  = "$PSScriptRoot\NTFSAudit.csv"
    )

    $CsvHeader = "Folder Path,IdentityReference,AccessControlType,IsInherited,InheritanceFlags,PropagationFlags"
    Set-Content -Value $CsvHeader -Path $OutFile 

    $Folders = Get-ChildItem $RootPath -Recurse | Where-Object { $_.PSIsContainer -eq $True }

    ForEach ($Folder in $Folders)
    {
        Try
        {
	        $ACLs = Get-Acl $Folder.FullName | ForEach-Object { $_.Access }
	        Foreach ($ACL in $ACLs)
            {
	            $OutInfo = $Folder.FullName.Replace(',',';'), $ACL.IdentityReference, $ACL.AccessControlType, $ACL.IsInherited, $ACL.InheritanceFlags, $ACL.PropagationFlags -Join ','
                Add-Content -Value $OutInfo -Path $OutFile
	        }
        }
        Catch
        {
            $OutInfo = $Folder.Fullname.Replace(',',';'), "UNABLE_TO_ACCESS", ",,," -Join ','
	        Add-Content -Value $OutInfo -Path $OutFile
        }
    }
}
