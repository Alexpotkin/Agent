$global:ver = "0.3.5.9b"
$ProgrammName = "Agent"
[bool]$errorflag = $false
[bool]$warningflag = $false
[bool]$errorpattern = $false
[string]$text = " "
[string]$message = " "
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
$ini, $global:debug = Get-IniContent ".\config.ini" # Parse Ini file
function Debuging {
    param($param_debug = $false, [string]$debugmessage, [string]$typemessage = "info", [bool]$anyway_log = $false)    
    try {
        if (($param_debug -eq $true) -or ($anyway_log -eq $true)) {
            write-log -message $debugmessage -type $typemessage 
            if (($typemessage -eq "error") -or ($typemessage -eq "warning")) {
                $global:debug_error_text = $global:debug_error_text + " " + $debugmessage
            }
        }
        elseif (($typemessage -eq "error") -or ($typemessage -eq "warning")) {
            $global:debug_error_text = $global:debug_error_text + " " + $debugmessage
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
        if ($errorflag) {
            $sErrorText = " ❌ "
        }
        else {
            $sErrorText = " ✅ "
        }
        if ($warningflag) {
            $sWarningText = " warning ⚠️ "
        }
        else {
            $sWarningText = " " 
        }
        $message = $message + " ver. " + $ver + $sErrorText + $sWarningText
        Debuging -param_debug $debug -debugmessage ("Inclusive parameters for sending a message: " + $message) -typemessage info -anyway_log $True
        $payload = @{
            "chat_id"    = $chatid;
            "text"       = "Name: $name" + '  ' + "Message: $message";
            "parse_mode" = 'HTML';
        }
        Invoke-WebRequest -Uri ("https://api.telegram.org/bot{0}/sendMessage" `
                -f $token) -Method Post -ContentType "application/json;charset=utf-8" `
            -Body (ConvertTo-Json  -Compress -InputObject $payload) -UseBasicParsing  | Out-Null
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("Error sending a message to telegram.Error : " + $PSItem) -typemessage error
    }  
}

function SendServer {
    param (
        $message = "message is empty", $errorflag = $false, $warningflag = $false, $route = "/event"
    )
    if ($ini.main.telemetr -eq "0") {
        Debuging -param_debug $debug -debugmessage ("Телеметрия отключена в файле конфигурации") -typemessage warning
        return
    }
    try {
        if ($ini.main.servermon -eq "") {
            $uri = "http://84.52.98.118:50000"
        }
        else {
            $uri = $ini.main.servermon
        }
        $token = loadToken
        if ($null -eq $token) {
            $filecode = ".\code.txt"
            if (Test-Path $filecode) {
                $code = Get-Content $filecode -TotalCount 1
                Debuging -param_debug $debug -debugmessage ("code load is file: " + $code)  -typemessage info -anyway_log $True
                $route = "/registration"
                $uritoken = $uri + $route
                $payload = @{
                    "code" = $code.ToString()
                } 
                $request = Invoke-RestMethod -Uri $uritoken -Method Post -ContentType "application/json;charset=utf-8"  -Headers $headers -Body (ConvertTo-Json  -Compress -InputObject $payload) -UseBasicParsing

                Debuging -param_debug $debug -debugmessage ("request response: " + $request)  -typemessage info
                if ($request.status -eq "ok") {
                    $filePath = ".\ID.txt"
                    Set-Content -Path $filePath -Value $request.message
                    SendmessageTelegram -message "Устройство успешно привязано" 
                    Clear-Content -Path $filecode
                }
                else {
                    Debuging -param_debug $debug -debugmessage ("request response error: " + $request.status)  -typemessage error -anyway_log $True
                    return
                }
            }
            else {
                Debuging -param_debug $debug -debugmessage ("Problem code")  -typemessage error -anyway_log $True
                return
            }   
        }
        $token = LoadToken
        if ($null -ne $token) {
            Debuging -param_debug $debug -debugmessage ("Token is loaded...")  -typemessage info
            $headers = @{
                "token" = $token;
            }
            $route = "/event"
            $uri = $uri + $route
            $payload = @{
                "message" = $message;
                "error"   = $errorflag;
                "warning" = $warningflag;
                "version" = $ver;
            } 
            $request = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json;charset=utf-8"  -Headers $headers -Body (ConvertTo-Json  -Compress -InputObject $payload) -UseBasicParsing  
            Debuging -param_debug $debug -debugmessage ("request response: " + $request.status)  -typemessage info -anyway_log $True
            if ($request.status -ne "ok") {
                Debuging -param_debug $debug -debugmessage ("request response error: " + $request.status + $request.message)  -typemessage error -anyway_log $True 
            }
        }
        
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("Error sending message servermon. Error: " + $PSItem) -typemessage error
    }  
}

function LoadToken {
    $filePath = ".\ID.txt"
    if (Test-Path $filePath) {
        $token = Get-Content $filePath -First 1
        if ([string]::IsNullOrWhiteSpace($token)) {
            $token = $null
        }
    }
    else {
        $token = $null
        Debuging -param_debug $debug -debugmessage ("Error read token is file") -typemessage warning

    }
    return $token
}

####LOG WRITE####
try {
    #Connection component write-log
    .\components\write-log.ps1
    write-log "$ProgrammName (ver $ver) started." 
    if ($debug) {
        Debuging -param_debug $debug -debugmessage (' Debagger is ON ⚠ ') -typemessage warning
    } 
}
catch {	
    $debug = $false	
    $global:debug_error_text = "Critical error.The log file will be disabled. Error loading functions write-log.ps1"   
}

####FINDPATTERN####
Debuging -param_debug $debug -debugmessage ("The task for checking the cobian log file is set - 1. go...") -typemessage info
function Findpattern {
    # function pattern analizator
    param($filelog, $n, $time, $pattern, $debug)
    try {
        #Reading file
        if (((Get-Date) - (Get-ChildItem $filelog).LastWriteTime).TotalMinutes -gt $time) {
            $text = "For the last time there are no changes in the log. Check backup parameters !!!"
            $errbackup = $true
            $errorpattern = $false
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
        if ($text -Match $pattern) {
            Debuging -param_debug $debug -debugmessage ($pattern + "  - found in string! " + $text) -typemessage info
            $errorpattern = $false
            $text = "Cobian task is done!"
        }
        else {
            $errorpattern = $true
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
if (($ini.cobian.cobian -eq 1) -and ([int16]$ini.cobian.time -lt 1)) {
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
if ($ini.main.update -eq "1" -or $ini.main.update -eq "2") {
    try {
        Debuging -param_debug $debug -debugmessage ("Checking the update...") -typemessage info -anyway_log $true
        .\components\update.ps1
    }
    catch {		
        Debuging -param_debug $debug -debugmessage ("Error loading functions update.ps1") -typemessage warning
    } 
    #function update
    $updateResult = Update $ini $ver

    if ($updateResult -eq 0) {
        Debuging -param_debug $debug -debugmessage ("Обновление скрипта не требуется ") -typemessage info -anyway_log $true
    }
}

###SEND AGENT INFO###
if (($global:errorcount -gt 0) -or ($global:warningcount -gt 0)) {
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