#$ComponentName = "write-log"
New-Item -ItemType directory log -Force | out-null 
[int]$global:errorcount = 0 
[int]$global:warningcount = 0 
$ArchiveDir = ".\log\archive"
$LogDir = ".\log"
New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null 
function global:Compress-OldLog {
    $yesterday = (Get-Date).AddDays(-1).ToString("dd-MM-yyyy")
    $yesterdayLog = Join-Path -Path $LogDir -ChildPath "$yesterday.log"
    $archiveFile = Join-Path -Path $ArchiveDir -ChildPath "$yesterday.zip"

    if (Test-Path $yesterdayLog) {
        Compress-Archive -Path $yesterdayLog -DestinationPath $archiveFile -Force
        Remove-Item $yesterdayLog -Force
    }

    # Удаление старых архивов, если их больше 10
    $allArchives = Get-ChildItem -Path $ArchiveDir -Filter "*.zip"
    if ($allArchives.Count -gt 10) {
        $allArchives | Sort-Object CreationTime | Select-Object -First ($allArchives.Count - 10) | Remove-Item -Force
    }
}

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
Compress-OldLog