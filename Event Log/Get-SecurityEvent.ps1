Param
(
	$ComputerName = 'localhost',
	$UserName     = '*'
)

$Events = Invoke-Command -ComputerName $ComputerName -ScriptBlock `
{Get-WinEvent -LogName Security}

# This filtering below ought to be put into the scriptblock
$Output = @()
ForEach( $Event in $Events )
{
    Try
    {
        $Message = ( $Event.Message -split 'Account For Which Logon Failed:' )[1]
        $Output += $Message | Select `
        @{
            Name       = 'TimeCreated'
            Expression = { $Event.TimeCreated }
        }, `
        @{
            Name       = 'AccountName'
            Expression = { ( ( [regex]::Match($Message,'[\n\r].*Account Name:\s*([^\n\r]*)').Value ).Split(':')[1] ).Trim() }
        }
    }
    Catch{}
}

Write-Output $Output | Where { $_.AccountName -like $UserName }
