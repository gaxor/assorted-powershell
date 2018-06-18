# Objective:
# Script to clean up unneeded user profiles from servers

# Original Form by Denis Cooper: https://gallery.technet.microsoft.com/scriptcenter/Delete-user-profiles-over-05348eef
# Self-elevating script by Benjamin Armstrong: https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
# Compiled/modified by Greg Rowe, April 2016

Function SetupForm
{
	# Set up the form
	[void] [System.Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" )
	[void] [System.Reflection.Assembly]::LoadWithPartialName( "System.Drawing" )
	
	$objForm                  = New-Object System.Windows.Forms.Form
	$objForm.Text             = "Select user(s)"
	$objForm.Size             = New-Object System.Drawing.Size(395,320)
	$objForm.StartPosition    = "CenterScreen"

	$btnDelete                = New-Object System.Windows.Forms.Button
	$btnDelete.Location       = New-Object System.Drawing.Size(120,240)
	$btnDelete.Size           = New-Object System.Drawing.Size(75,23)
	$btnDelete.Text           = "Purge User"
	$objForm.Controls.Add( $btnDelete )
	$btnDelete.Add_Click( { Confirm } )

	$CancelButton             = New-Object System.Windows.Forms.Button
	$CancelButton.Location    = New-Object System.Drawing.Size(200,240)
	$CancelButton.Size        = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text        = "Cancel"
	$CancelButton.Add_Click( { $objForm.Close() } )
	$objForm.Controls.Add( $CancelButton )

	$objLabel                 = New-Object System.Windows.Forms.Label
	$objLabel.Location        = New-Object System.Drawing.Size(10,20)
	$objLabel.Size            = New-Object System.Drawing.Size(310,20)
	$objLabel.Text            = "Please select user(s) to delete profile:"
	$objForm.Controls.Add( $objLabel )

	$objListBox               = New-Object System.Windows.Forms.ListBox
	$objListBox.Sorted        = $True
	$objListBox.Location      = New-Object System.Drawing.Size(10,40)
	$objListBox.Size          = New-Object System.Drawing.Size(360,300)
	$objListBox.Height        = 180
	$objListBox.SelectionMode = "MultiExtended"
	
	# List all members of the group
	$RDCMem                   = Get-ADUser -Filter * -SearchBase $RDCOU -SearchScope Subtree -Properties Homedirectory | Select Name,SamAccountName,Homedirectory

	# Adds the users to the combo box
	ForEach($user in $RDCMem)
    {
		[void] $objListBox.Items.Add($user.Name+"  ::  "+$user.SamAccountName)
	}

	$objForm.Controls.Add( $objListBox )
	$objForm.Topmost = $True
	$objForm.Add_Shown( { $objForm.Activate() } )
    Write-Host -ForegroundColor Cyan 'Selection window is open; use that to select user(s).'
	[void] $objForm.ShowDialog()
}

Function Confirm
{
	$objListBox.SelectedItems | ForEach-Object { $SelUsrLst += $_ + "`r`n" }
	$Confirm = [System.Windows.Forms.MessageBox]::Show(
		# Message text
		"Purge all data and accounts for the following users? `r`n$SelUsrLst",`
		# Box title
		'Confirm',`
		# Buttons
		'YesNoCancel',`
		# Picture
		'Warning'
	)
	If( $Confirm -eq 'Yes' )
    {
        RightNow
		Add-Content $log "$date INFO: $me has Confirmed to purge the following users:`r`n $SelUsrLst"
		CheckLogon
	}
}

Function CheckLogon
{
	# Get logged on users for each server
	Write-Host -ForegroundColor Cyan 'Retrieving logged on users...'
	$LoggedOn = ForEach($Server in $Servers){Get-ActiveUser $Server -Method Query}
	$Logged   = $LoggedOn.UserName

	ForEach( $UserN in $objListBox.SelectedItems )
    {
		# Change user variables for script execution
        $UserName = [array]$UserN.split("{: }")[-1]
		
		# Check if user is logged on
        RightNow
		If($Logged -notcontains "$UserName")
        {
			Write-Host -ForegroundColor Cyan "$UserName is not logged on anywhere; continuing."
            Add-Content $log "$date INFO: User $UserName is not logged on anywhere; starting purge."
			PurgeUser
		}
		Else
        {
			Write-Host -ForegroundColor Red "User $UserName is logged on! Skipping purge."
            Add-Content $log "$date Error: User $UserName is logged on! Skipping purge."
		}
	}
}

Function PurgeUser
{
	# Delete redirected (aka client desktop) dir
	Write-Host -ForegroundColor Cyan "Attempting to delete Redirected Desktop for $UserName..."
	Add-Content $log "$date INFO: Begin purge for: $UserName."
	Try
    {
		$RedirDesk = "\\$DataServer\desktops\" + "$UserName"
		Remove-Item -Recurse -Force $RedirDesk -ErrorAction Stop
		Write-Host -ForegroundColor Green "Success! $RedirDesk has been deleted."
	    RightNow
		Add-Content $log "$date SUCCESS: $UserName - $RedirDesk has been deleted by $me."
	}
	Catch [System.IO.IOException]
    {
	    RightNow
		Write-Host -ForegroundColor Red "ERROR: Redirected Desktop is currently locked on $DataServer - please use log off user first"
		Add-Content $log "$date ERROR: $UserName Redirected Desktop is currently locked on $DataServer - please use log off user first"
	}
	Catch [System.Management.Automation.RuntimeException]
    {
	    RightNow
		Write-Host -ForegroundColor Yellow "INFO: $UserName Profile does not exist on $DataServer"
		Add-Content $log "$date INFO: $UserName Redirected Desktop does not exist on $Server"
	}
	Catch
    {
	    RightNow
		$DelProfErr = $error[0].Exception.GetType().FullName
		Write-Host -ForegroundColor Red 'ERROR: an unknown error occurred. See log for details'
		Add-Content $log "$date ERROR: an unknown error occurred. To catch this error, try: $DelProfErr `r`n The error response was:`r`n $Error[0]"
	}

	# Delete local profiles on all servers
	Write-Host -ForegroundColor Cyan "Attempting to delete local profiles for $UserName..."
	ForEach ( $Server in $Servers )
    {
		Try
        {
			( Get-WmiObject -ComputerName $Server Win32_UserProfile | Where { $_.LocalPath -eq "C:\Users\$UserName" } ).Delete()
			Write-Host -ForegroundColor Green "Success! $UserName has been deleted from $Server"
	        RightNow
		    Add-Content $log "$date SUCCESS: 'C:\Users\$UserName' has been deleted from $Server by $me."
		}
		Catch [System.Management.Automation.MethodInvocationException]
        {
	        RightNow
			Write-Host -ForegroundColor Red "ERROR: Profile is currently locked on $Server - please use log off user first"
			Add-Content $log "$date ERROR: $UserName Profile is currently locked on $Server - please use log off user first"
		}
		Catch [System.Management.Automation.RuntimeException]
        {
	        RightNow
			Write-Host -ForegroundColor Yellow "INFO: $UserName Profile does not exist on $Server"
			Add-Content $log "$date INFO: $UserName Profile does not exist on $Server"
		}
		Catch
        {
	        RightNow
			$DelProfErr = $error[0].Exception.GetType().FullName
			Write-Host -ForegroundColor Red 'ERROR: an unknown error occurred. See log for details'
			Add-Content $log "$date ERROR: an unknown error occurred. The error response was:`r`n $error[0] `r`n To catch this error, try: $DelProfErr"
		}
	}

	# Check if current user's 'Client Data' directory is unique
    Write-Host -ForegroundColor Cyan 'Checking Client Data directory...'
    $UsrPrp              = Get-ADUser -Identity "$UserName" -Properties HomeDirectory
    $UsrDir              = $UsrPrp.HomeDirectory
    $UsrDirSub           = $UsrPrp.HomeDirectory.Split("\")[4]
    [array]$RDCMemDirLst = 'blah','blah2'
    ForEach( $MemUsr in $RDCMem )
    {
        If( $MemUsr.Homedirectory -eq $null )
        { continue }
        $RDCMemDirLst += ( $MemUsr.HomeDirectory.Split("\")[4] )
    }

    $DirUnq    = $RDCMemDirLst -match "$UsrDirSub"
    $DirUnqCnt = $DirUnq.count

    # Delete directory only if the client homedrive root location is unique
    If( $DirUnqCnt -gt 1 )
    {
        Write-Host -ForegroundColor Yellow "INFO: Other users have the Client Data directory: $UsrDirSub"
        Write-Host -ForegroundColor Yellow "INFO: Not deleting Client Data directory."
	    RightNow
        Add-Content $log "$date INFO: Client Data directory: $UsrDirSub is not unique. Not deleting directory."
    }
    Else
    {
        Try
        {
            Write-Host -ForegroundColor Cyan "INFO: Deleting unique Client Data directory: $UsrDirSub"
		    Remove-Item -Recurse -force "$UsrDir" -ErrorAction Stop
            Write-Host -ForegroundColor Green "Success: Client Data directory has been deleted."
            RightNow
            Add-Content $log "$date Success: Client Data directory deleted."
        }
        Catch
        {
            Write-Host -ForegroundColor Red "ERROR: Deleting Client Data directory failed for $UserName. See log for details."
            RightNow
            Add-Content $log "$date ERROR: Deleting Client Data directory failed for $UserName. Location: $UsrDir The response was:`r`n $Error[0]"
        }
    }

	# Delete user in AD
	Write-Host -ForegroundColor Cyan "Deleting $UserName from Active Directory..."
	Try
    {
        Remove-ADUser -Identity "$UserName" -Confirm:$FALSE
        RightNow
	    Write-Host -ForegroundColor Green "Sucess: $UserName removed from Active Directory."
        Add-Content $log "$date Sucess: $UserName removed from Active Directory by $me."
    }
    Catch
    {
	    RightNow
        Write-Host -ForegroundColor Red 'Error: Skipping AD user-delete. See log for details.'
	    Add-Content $log "$date Error: AD user-delete skipped for $UserName. The response was:`r`n $Error[0]"
    }
	RightNow
	Write-Host -ForegroundColor Green "Sucess: $UserName purge complete."
    Add-Content $log "$date Sucess: $UserName purge complete."
}

Function RightNow
{
    # Get current time for logs ( get-date syntax: https://technet.microsoft.com/en-us/library/ee692801.aspx )
    Set-Variable -Name date -Value ( Get-Date -Format g ) -Scope Global
}

$ver                =  1.1
[array] $Servers    = "ts1","ts2","ts3"
$DataServer         = "data1"
$log                = "\\data1\_deletion_log\log.txt"
$SoftwareLocation   = "\\data1\software\PowerShell\Modules\Get-ActiveUser"
$me                 = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$RDCOU              = "OU=Users,DC=DOMAIN,DC=TLD"

# Check to see if we are currently running "as Administrator"
$myWindowsID        =[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal =new-object System.Security.Principal.WindowsPrincipal( $myWindowsID )
$adminRole          =[System.Security.Principal.WindowsBuiltInRole]::Administrator
If ( $myWindowsPrincipal.IsInRole( $adminRole ) )
{
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   clear-host
}
Else
{
   # We are not running "as Administrator" - so relaunch as administrator
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   # Specify the current script path and name as a parameter
   #$newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   # Exit from the current, unelevated, process
   exit
}

# Print script info
Write-Host -ForegroundColor Green '      ' 'RDC Cleanup' "$ver"
Write-Host -ForegroundColor Green 'INFO: Script to clean up unneeded user profiles from RDC servers'
Write-Host -ForegroundColor Yellow "INFO: Logs can be found at $log"`r`n

# Import 'Get-ActiveUser' powershell module (required for next step)
Write-Host -ForegroundColor Cyan 'Importing required modules...'
If( Get-Module -ListAvailable -Name Get-ActiveUser )
{
	Import-Module Get-ActiveUser
}
Else
{
	# Install 'Get-ActiveUser' cmdlet
	Write-Host -ForegroundColor Cyan 'Installing cmdlet: Get-ActiveUser'
	Copy-Item $SoftwareLocation "C:\Program Files\WindowsPowerShell\Modules" -Recurse
	Import-Module -Name 'C:\Program Files\WindowsPowerShell\Modules\Get-ActiveUser\Get-ActiveUser.psm1'
}

# Import AD module
If( Get-Module -ListAvailable -Name ActiveDirectory )
{
	Import-Module ActiveDirectory
}
Else
{
    Try
    {
	    Write-Host -ForegroundColor Yellow "INFO: AD Module not installed, attempting to install RSAT..."
	    Add-WindowsFeature RSAT-AD-PowerShell
	    Import-Module ActiveDirectory
    }
    Catch
    {
	    Write-Host -ForegroundColor Red "ERROR: Unable to import AD module. Please install 'Remote Server Adminsitration Tools' and try again."
	    pause
	    exit
    }
}
Write-Host -ForegroundColor Cyan 'Modules imported. Opening selection window...'

# Open user-selection window
SetupForm