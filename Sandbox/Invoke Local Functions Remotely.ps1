Function Write-Hostname
{
	Write-Warning $(hostname)
}

Function Write-GUID
{
	Write-Warning $( [GUID]::NewGuid() )
}

$ComputerName   = $env:COMPUTERNAME
$Write_Hostname = ${ $Function:Write-Hostname }
$Write_GUID	    = ${ $Function:Write-GUID }

# FAILED
$Args1 = @{
    ComputerName = $ComputerName
    ArgumentList = @(
        $Write_Hostname
        $Write_GUID
    )
    ScriptBlock = {
        Param
        (
            $Write_Hostname,
			$Write_GUID
        )

        . ([ScriptBlock]::Create( $Write_Hostname ))
        . ([ScriptBlock]::Create( $Write_GUID ))

		Write-Hostname
		Write-GUID
    }
}

# FAILED
$Args2 = @{
    ComputerName = $ComputerName
    ArgumentList = $Write_GUID
    ScriptBlock = {
		Param( $Write_GUID )
		
        . ([ScriptBlock]::Create( $Write_GUID ))
        Write-GUID
    }
}

# WORKING!
$Args3 = @{
    ComputerName = $ComputerName
    ScriptBlock = {
		${ Write-GUID }
	}
}

#Invoke-Command @Args1
#Invoke-Command @Args2
Invoke-Command @Args3
