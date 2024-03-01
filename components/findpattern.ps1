#$ComponentName = "findpattern"
Debuging -param_debug $debug -debugmessage ("The task for checking the cobian log file is set - 1. go...") -typemessage info
function global:Findpattern {
    # function cobian analizator
    param($filelog, $n, $time, $pattern, $debug)
    try {
        #Reading file
        if (((Get-Date) - (Get-ChildItem $filelog).LastWriteTime).TotalMinutes -gt $time) {
            Debuging -param_debug $debug -debugmessage ("For the last - " + $time + " time there are no changes in the log: " + $filelog) -typemessage info -anyway_log $true 
            $text = "For the last " + $time + " time there are no changes in the log. Check backup parameters !!!"
            $errbackup = $true
        }
        else {
            Debuging -param_debug $debug -debugmessage "Reading log-file ..." -typemessage info
            $text = (get-content -path $filelog)[$n]
            Debuging -param_debug $debug -debugmessage ("Read " + $text) -typemessage info 
            if ( $null -eq $text) {
                $text = "The array of lines from the file contains null"
                Debuging -param_debug $debug -debugmessage $text  -typemessage warning -anyway_log $true 
            }
            $errbackup = $false
        }  
    }
    catch {
        [string]$errs = Get-ChildItem($filelog)  2>&1 
        $text = $errs
        Debuging -param_debug $debug -debugmessage ("Critical error." + $text)  -typemessage error -anyway_log $true 
        $errbackup = $true
    }
    #Send the line for verification if there are no errors of obtaining a line from a log or processing errors of this line!
    if ($true -ne $errbackup) {
        if ($text.Contains($pattern)) {
            Debuging -param_debug $debug -debugmessage ("Pattern found in string! " + $text) -typemessage info
            [bool]$errorpattern = $false
            $text = "Cobian task is done!"
        }
        else {
            [bool]$errorpattern = $true
            Debuging -param_debug $debug -debugmessage ("Pattern not found in string " + $text) -typemessage info
        }
    }
    else {
        Debuging -param_debug $debug -debugmessage ("Passing the line checking procedure.A message with an error will be sent!" )  -typemessage info 
        $errbackup = $true
    }
    return $text, $errbackup, $errorpattern
}