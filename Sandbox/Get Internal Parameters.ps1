# This will help get available parameters from within a function
# Be aware, it only collects the variable names from within the param() block

function Get-gci
{
    param
    (
        [string] $a,
        [switch] $b
    )

    (Get-Command Get-Childitem).parameters
}

$params = @{ a = 'a'; b = $true }
$Commgci = Get-Commgci @params
$Commgci -eq $null # false
$Commgci | get-member
#$Commgci.GetEnumerator() | foreach{ $_.gettype() }
((((Get-Help Get-Commgci).Syntax).SyntaxItem).Parameter).Name
