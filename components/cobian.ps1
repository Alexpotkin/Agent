#$ComponentName = "cobian"
function global:Cobian {
    # function cobian analizator
    param($ini)
    $cobianfolderlog = $ini.cobian.cobianfolderlog
    if (($ini.cobian.cobianfolderlog -eq "") -or ($NULL -eq $ini.cobian.cobianfolderlog )) {
        $cobianfolderlog = 'C:\Program Files (x86)\Cobian Backup 11\Logs\'
        Debuging -param_debug $debug -debugmessage ("The path parameter to the cobian log file is not set. Set the path by default") -typemessage info 
    }
    $n = -2..-2 #The parameter indicates which lines you need to read -2 ..- 2 meant to read the penultimate line
    $date = get-date -uformat "%Y-%m-%d"
    $filelog = $cobianfolderlog + 'log ' + $date + '.txt'
    $time = $ini.cobian.time
    $pattern = "Ошибок: 0,"
    $text, $errbackup, $errorpattern = Findpattern $filelog $n $time $pattern 
    if ($true -eq $errorpattern) {
        $n = -1..-1
        $pattern = "Добро пожаловать в Cobian Backup"
        $text, $errbackup, $errorpattern = Findpattern $filelog $n $time
        $text = "Добро пожаловать в Cobian Backup. Сервис успешно запущен!"
    }
    return  $text, $errbackup, $errorpattern
}