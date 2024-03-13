$global:ver = "0.1.0"
$ProgrammName = "Agent"
function Get-IniContent ($filePath) {
    ##Parsing file ini file, function returns an array $ini. We call the function:on:$ini = Get-IniContent ".\\config.ini"
    ## The array of keys $ ini contains the name of the section, the name of the key and meaning.example ($chatid = $ini.main.chatid)
    try {
        Write-Host ("Reading parameters from a file...")
        $ini = @{}
        switch -regex -file $FilePath {
            '^\[(.+)\]' {
                # Section
                $ini_section = $matches[1]
                $ini[$ini_section] = @{}
                $CommentCount = 0
                Write-Host ("Section: " + $ini_section)
            }
            '^(;.*)$' {
                # Comment
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $paramname = "Comment" + $CommentCount
                $ini[$ini_section][$name] = $value
            }
            '(.+?)\s*=(.*)' {
                # Key
                $paramname, $value = $matches[1..2]
                $ini[$ini_section][$paramname] = $value
                Write-Host ($paramname + "=" + $value)
            }
        }
        $debugini = $ini.main.debug
        if (($debugini) -ne "0") {
            $debug = $true
        }
        else {       
            $debug = $false
        }
        return $ini, $debug
    }
    catch {		
        exit
    }
}
$global:debug_error_text = ""
$ini, $global:debug = Get-IniContent ".\config.ini" # Parsim Ini file and we get the parameters we need
function Debuging {
    param($param_debug = $false, [string]$debugmessage, [string]$typemessage = "info", [bool]$anyway_log = $false)    
    try {
        if ($param_debug -eq $true ) {
            write-log -message $debugmessage -type $typemessage 
            if (($typemessage -eq "error") -or ($typemessage -eq "warning")) {
                $global:debug_error_text = $global:debug_error_text + $debugmessage
            }
        }
        elseif ($anyway_log -or ($typemessage -eq "error") -or ($typemessage -eq "warning")) {
            $global:debug_error_text = $global:debug_error_text + $debugmessage
            write-log -message $debugmessage -type $typemessage
        }
    }
    catch {
        $global:debug_error_text = "Error debugging function"
    }
} 
function SendMessageTelegram {
    #Sending message to the telegram
    param (
        $message = "message is empty", $token = $ini.main.token, $chatid = $ini.main.chatid, $name = $ini.main.name, $errorflag = $false, $warningflag = $false
    ) 
    try {
        $message = $message + " ver. " + $ver + " Error: " + $errorflag + " Warn: " + $warningflag
        Debuging -param_debug $debug -debugmessage ("Inclusive parameters for sending a message: " + $message) -typemessage info
        $payload = @{
            "chat_id"    = $chatid;
            "text"       = "Name: $name" + ' ' + "Message: $message";
            "parse_mode" = 'HTML';
        }
        Invoke-WebRequest -Uri ("https://api.telegram.org/bot{0}/sendMessage" `
                -f $token) -Method Post -ContentType "application/json;charset=utf-8" `
            -Body (ConvertTo-Json  -Compress -InputObject $payload)  | Out-Null
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("Error sending a message to the server.Error : " + $PSItem) -typemessage error
    }  
}

function SendServer {
    param (
        $message = "message is empty", $errorflag = $false, $warningflag = $false
    )
    try {
        $uri = "http://84.52.98.118:50000/event"
        $message = "54545"
        $payload = @{
            "token" = $SaveloadID 
            "message"    = $message;
            "errorflag" = $errorflag;
            "warningflag" = $warningflag;
            "ver"       = $ver;
        } 
        $request = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json;charset=utf-8" `
                    -Body (ConvertTo-Json  -Compress -InputObject $payload)
        Debuging -param_debug $debug -debugmessage ("request response: " +$request.status)  -typemessage error
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("Error sending a message to the server 82.Error  : " + $PSItem) -typemessage error
    }  
}

function SaveloadID {
    $filePath = ".\ID.txt"
    if (Test-Path $filePath) {
        $ID = Get-Content $filePath -TotalCount 1
    }
    else {
        $ID = "66574546456hjhgj456546"
        Set-Content -Path $filePath -Value $ID
    }
    return $ID
}

####LOG WRITE####
try {
    #Connection component write-log
    .\components\write-log.ps1
    write-log "$ProgrammName (ver $ver) started." 
    if ($debug) {
        Debuging -param_debug $debug -debugmessage ("Debug options is ON") -typemessage warning
    } 
}
catch {	
    $debug = $false	
    $global:debug_error_text = "Critical error.The log file will be disabled. Error loading functions write-log.ps1"   
}

####FINDPATTERN####
#$ComponentName = "findpattern"
Debuging -param_debug $debug -debugmessage ("The task for checking the cobian log file is set - 1. go...") -typemessage info
function Findpattern {
    # function pattern analizator
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
        if ($text  -Match  $pattern) {
            Debuging -param_debug $debug -debugmessage ($pattern + "  - found in string! " + $text) -typemessage info
            [bool]$errorpattern = $false
            $text = "Cobian task is done!"
        }
        else {
            [bool]$errorpattern = $true
            Debuging -param_debug $debug -debugmessage ($pattern + " - not found in string " + $text) -typemessage info
        }
    }
    else {
        Debuging -param_debug $debug -debugmessage ("Passing the line checking procedure.A message with an error will be sent!" )  -typemessage info 
        $errbackup = $true
    }
    return $text, $errbackup, $errorpattern
}



####COMPONENT COBIAN####
if (($ini.cobian.cobian -eq 1) -or ([int16]$ini.cobian.time -lt 1)) {
    try {
        .\components\cobian.ps1 #connect global function 
    }
    catch {
        $text = "Error loading functions cobian.ps1"
        Debuging -param_debug $debug -debugmessage $text -typemessage error
    }
    $text, $errbackup, $errorpattern = Cobian $ini
    if (($True -eq $errbackup) -or ($True -eq $errorpattern)) {
        $text = "ERROR " + $text  
        $errorflag = $true
    }
    SendmessageTelegram -message $text -errorflag $errorflag
    SendServer -message $text -errorflag $errorflag
}

####UPDATE####
if ($ini.main.update -eq "1") {
    try {
        Debuging -param_debug $debug -debugmessage ("Checking the update...") -typemessage info -anyway_log $true
        .\components\update.ps1
    }
    catch {		
        Debuging -param_debug $debug -debugmessage ("Error loading functions update.ps1") -typemessage warning
    } 
    #function update
    $updateResult = Update $ini $ver

    if ($updateResult -eq 1) {
        Debuging -param_debug $debug -debugmessage ("Update downloaded! ") -typemessage completed -anyway_log $true
    }
    elseif ($updateResult -eq 2) {
        Debuging -param_debug $debug -debugmessage ("ERROR updateted script!") -typemessage warning -anyway_log $true
    }
}

####SEND AGENT INFO####
if (($global:errorcount -gt 0) -or ($global:warningcount -gt 0)) {
    $warningflag = $false
    $errorflag = $false
    if ($global:errorcount -gt 0) {
        $errorflag = $true
    }
    if ($global:warningcount -gt 0) {
        $warningflag = $true
    }
    $message = "Attention! Errors: " + $global:errorcount + " " + "Warnings: " + $global:warningcount + " " + "info: " + $global:debug_error_text
    SendmessageTelegram -message $message  -errorflag $errorflag -warningflag $warningflag
}
#END#
Debuging -param_debug $debug -debugmessage ("The debugger completes the work") -typemessage completed
Debuging -param_debug $debug -debugmessage ("Script completed.") -typemessage completed -anyway_log $True