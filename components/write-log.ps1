#$ComponentName = "write-log"
New-Item -ItemType directory log -Force | out-null 
[int]$global:errorcount = 0 
[int]$global:warningcount = 0 
function global:Write-log { 
	param($message, [string]$type = "info", $logfile = ".\log\" + (Get-Date -Format "dd-MM-yyyy") + ".log")	
	$dt = Get-Date -Format "dd.MM.yyyy HH:mm:ss"	
	$msg = $dt + "`t" + $type + "`t" + $message #format date: 01.01.2001 01:01:01 [tab] error [tab] message
	Out-File -FilePath $logfile -InputObject $msg -Append -encoding unicode
	switch ( $type.toLower() ) {
		"error" {			
			$global:errorcount++
			write-host $msg -ForegroundColor red			
		}
		"warning" {			
			$global:warningcount++
			write-host $msg -ForegroundColor yellow
		}
		"completed" {			
			write-host $msg -ForegroundColor green
		}
		"info" {			
			write-host $msg
		}			
		default { 
			write-host $msg
		}
	}
}