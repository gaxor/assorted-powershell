# List update history
$Session      = New-Object -ComObject Microsoft.Update.Session
$Searcher     = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()

$UpdateHistory = $Searcher.QueryHistory( 0, $HistoryCount ) | Select-Object Date,Title,
    @{
	    Name       = 'Operation'
	    Expression =
       {
		    Switch ( $_.Operation )
		    {
			    1 { 'Installation' }
			    2 { 'Uninstallation' }
			    3 { 'Other' }
		    }
	    }
    },
    @{
	    Name       = 'Status'
	    Expression =
	    {
		    Switch ( $_.ResultCode )
		    {
			    1 { 'In Progress' }
			    2 { 'Succeeded' }
			    3 { 'Succeeded With Errors' }
			    4 { 'Failed' }
			    5 { 'Aborted' }
		    }
	    }
    }

# Different views
$UpdateHistory | Out-GridView
$UpdateHistory | Format-Table -AutoSize
$UpdateHistory | Format-List