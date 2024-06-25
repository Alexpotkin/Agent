function global:Update {
    <#
    Returns:
    1 - Update successful
    2 - Error update
    0 - Скрипт уже актуальной версии
    #>
    param($ini)
    $ModulName = "module-Update"
    $fileScript = ".\script.ps1"
    $repoUrl = "https://api.github.com/repos/Alexpotkin/Agent/releases"
    
    try {
        $response = Invoke-RestMethod -Uri $repoUrl
        $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        $latestPreRelease = $response | Where-Object { $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        
        # Определение URL для установки в зависимости от значения $ini.main.update
        write-host ($latestVersion)
        if ($ini.main.update -eq 2) {
            $latestVersion = $latestPreRelease.tag_name ##0.3.5.6b example
            if ($ver -eq $latestVersion) {
                return  $updateResult = 0
            }
            Debuging -param_debug $debug -debugmessage ("Найдена экспериментальная версия - " + $latestVersion) -typemessage completed -anyway_log $True
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestPreRelease.tag_name + ".zip"
            if (-not ($zipUrl -match "^https?://")) {
                throw "URL не валиден!"
                return $updateResult = 2  #error
            }
            else {
                Debuging -param_debug $debug -debugmessage ("Путь к файлу предрелизной версии: " + $zipUrl) -typemessage completed -anyway_log $true
            }
        }
        else {
            $latestVersion = $latestRelease.tag_name
            if ($ver -eq $latestVersion) {
                return  $updateResult = 0
            }
            Debuging -param_debug $debug -debugmessage ("Доступно обновление-" + $latestVersion) -typemessage completed -anyway_log $True
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestRelease.tag_name + ".zip"
            if (-not ($zipUrl -match "^https?://")) {
                throw "URL не валиден!"
                return $updateResult = 2  #error
            }
            else {
                Debuging -param_debug $debug -debugmessage ("Путь к файлу релизной версии: " + $zipUrl) -typemessage completed -anyway_log $true
            }
        }
        $zipPath = ".\update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
        Remove-Item $zipPath
        ##Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination ".\" -Recurse -Force
        
        $firstLine = Get-Content -Path $fileScript -TotalCount 1
        if ($firstLine -match '(\d+(\.\d+){0,3}\w*)') {
            $updatedVersion = $matches[0]
            if ($latestVersion -eq $updatedVersion) {
                Debuging -param_debug $debug -debugmessage ("Скрипт успешно обновлен на версию" + $updatedVersion)  -typemessage completed -anyway_log $true
                Remove-Item ".\temp" -Recurse -Force
                return $updateResult = 1
            }
            else {
                Debuging -param_debug $debug -debugmessage ("Скрипт не обновлен. Текущая версия - " + $updatedVersion)  -typemessage warning -anyway_log $true
                Remove-Item ".\temp" -Recurse -Force
                return $updateResult = 2
            }
        }
        else {
            Debuging -param_debug $debug -debugmessage ("заголовок скрипта не содержит номер версии")  -typemessage completed -anyway_log $true
        }
        return $updateResult = 2
        
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("CATCH-($ModulName) $_ ") -typemessage warning -anyway_log $True
        return $updateResult = 2
    }
}
