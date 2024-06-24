function global:Update {
    # функция обновления
    param($ini, $ver)
    $repoUrl = "https://api.github.com/repos/Alexpotkin/Agent/releases"
    
    try {
        $response = Invoke-RestMethod -Uri $repoUrl
        
        $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        $latestPreRelease = $response | Where-Object { $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        
        # Определение URL для установки в зависимости от значения $ini.main.update
        if ($ini.main.update -eq 2) {
            $latestVersion = $latestPreRelease.tag_name
            $updateType = "предрелизная"
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestPreRelease.tag_name + ".zip"

            if (-not $zipUrl) {
                throw "Не удалось найти URL для предрелизной версии."
            }
            Write-Host "Путь к файлу предрелизной версии: $zipUrl"
        }
        else {
            $latestVersion = $latestRelease.tag_name
            $updateType = "релизная"
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestRelease.tag_name + ".zip"

            if (-not $zipUrl) {
                throw "Не удалось найти URL для релизной версии."
            }
        }
        
        $zipPath = ".\update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
        Remove-Item $zipPath
        
        Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination ".\" -Recurse -Force
        ## Remove-Item ".\temp" -Recurse -Force
        return $updateResult = 1
        
        if ($latestVersion -eq $ver) {
            Debuging -param_debug $debug -debugmessage ("Скрипт уже обновлен до версии - ($ver)") -typemessage info -anyway_log $true
            return $updateResult = 0
        }
    }
    catch {
        Write-Host "Произошла ошибка при выполнении обновления: $_"
        return $updateResult = 2
    }
}
