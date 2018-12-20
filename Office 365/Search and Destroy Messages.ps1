# By Greg Rowe July 2018

# --------------------------------------------------------- #
# PREREQUISITE: Connect to Exchange Online
# --------------------------------------------------------- #

$UserEmail   = 'user1@domain.com'
$Credentials = Import-Clixml -Path "$home\documents\windowspowershell\creds.xml"

Connect-EXOPSSession -Credential $Credentials

# --------------------------------------------------------- #
# SETUP ONLY: Give yourself proper permissions to run the rest of the script
# --------------------------------------------------------- #
    # Create "Mailbox Import-Export Management" role group
    # NOTE: If you add yourself to these groups, you'll need to wait for permissions to sync and restart the EXOP console

New-RoleGroup 'Mailbox Import-Export Management' -Roles 'Mailbox Import Export' -ErrorAction SilentlyContinue
'Organization Management','Compliance Management','Mailbox Import-Export Management' | ForEach { Add-RoleGroupMember -Identity $_ -Member $UserEmail }

# --------------------------------------------------------- #
# SETUP ONLY: Disable single item recovery
# --------------------------------------------------------- #
    # This section only runs against current user, it'd be nice to update it and run for all users
# $Mailbox = Get-Mailbox -Identity $UserEmail
# Get-Mailbox -ResultSize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox')} | Set-Mailbox -RetainDeletedItemsFor 0
# $Mailbox.RetainDeletedItemsFor
# $Mailbox.SingleItemRecoveryEnabled
# Set-Mailbox -Identity $UserEmail -SingleItemRecoveryEnabled $false

# --------------------------------------------------------- #
# PRE-EXECUTE: Set required variables
# --------------------------------------------------------- #

# Email address of user who wants matching emails
$TargetMailbox = $UserEmail

# SearchQuery syntax help found here: https://docs.microsoft.com/en-us/Exchange/policy-and-compliance/ediscovery/message-properties-and-search-operators
$SearchQuery   = 'subject:"unwanted subject title" AND "unwanted text in body"'

# Name of folder to copy matched emails to
$TargetFolder  = "Search.$name.$((Get-Date -Format g).replace(' ','.'))"

# --------------------------------------------------------- #
# EXECUTE: Search one user & copy emails to a mailbox
# --------------------------------------------------------- #
$name = 'user2'
$SearchParams = @{
    # Identity: mailbox to search
    Identity      = "$name@domain.com"
    SearchQuery   = $SearchQuery
    # TargetMailbox: mailbox to copy mail to
    TargetMailbox = $TargetMailbox
    # TargetFolder: folder name to copy mail to
    TargetFolder  = $TargetFolder
    Force         = $True
}
Search-Mailbox @SearchParams

# --------------------------------------------------------- #
# EXECUTE: Search all users, copy emails to a mailbox, & delete emails from users' mailboxes
# --------------------------------------------------------- #
$SearchParams = @{
    SearchQuery   = $SearchQuery
    TargetMailbox = $TargetMailbox
    TargetFolder  = $TargetFolder
    DeleteContent = $True
    Force         = $True
}
Get-Mailbox | Search-Mailbox @SearchParams

# --------------------------------------------------------- #
# EXECUTE: Run search on target mailbox (if TargetMailbox was specified in prevous execution)
# --------------------------------------------------------- #
$SearchParams = @{
    SearchQuery   = $SearchQuery
    Identity      = $UserEmail
    DeleteContent = $True
    Force         = $True
}
Search-Mailbox @SearchParams
