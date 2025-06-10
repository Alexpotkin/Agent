function global:Update {
    <#
    Returns:
    1 - Update successful
    2 - Error update
    3 - Developer MODE
    0 - Script is already up-to-date
    #>
    param($ini)

    $ModulName = "module-Update"
    $fileScript = ".\script.ps1"
    $repoUrl = "https://api.github.com/repos/Alexpotkin/Agent/releases"
    $configFilePath = ".\config.ini"
    $defaultConfigFilePath = ".\default_config.ini"  # Путь к шаблону конфигурации

    function Get-VersionFromScript($filePath) {
        $firstLine = Get-Content -Path $filePath -TotalCount 1
        if ($firstLine -match '(\d+(\.\d+){0,3}\w*)') {
            return $matches[0]
        }
        else {
            throw "Script header does not contain a version number"
        }
    }

    function Update-Module($zipUrl, $latestVersion, $isDevelop) {
        $zipPath = ".\update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
        Remove-Item $zipPath

        if ($isDevelop -ne 1) {
            Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination ".\" -Recurse -Force
            Update-ConfigFile -configFilePath $configFilePath -defaultConfigFilePath $defaultConfigFilePath  # Обновление конфигурации
        }
        else {
            return 3  # Script off, developer mode
        }

        Remove-Item ".\temp" -Recurse -Force
    }

    function Update-ConfigFile {
        param(
            [string]$configFilePath,
            [string]$defaultConfigFilePath
        )

        # Если конфигурационный файл отсутствует, создаем его на основе шаблона
        if (-not (Test-Path $configFilePath)) {
            Copy-Item -Path $defaultConfigFilePath -Destination $configFilePath
            Write-Host "Файл $configFilePath был создан из $defaultConfigFilePath."
            return
        }

        # Читаем существующий конфигурационный файл
        $existingConfig = Get-Content -Path $configFilePath
        $newParams = @{}
        $currentSection = ''

        # Читаем новый конфигурационный файл по умолчанию
        $defaultConfig = Get-Content -Path $defaultConfigFilePath

        # Считываем существующие параметры с учетом секций
        foreach ($line in $existingConfig) {
            if ($line -match '^\[(.+)\]$') {
                # Секция
                $currentSection = $matches[1].Trim()
                $newParams[$currentSection] = @{}
            }
            elseif ($line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                # Параметр
                if ($currentSection -ne '') {
                    $newParams[$currentSection][$matches["key"].Trim()] = $matches["value"].Trim()
                }
            }
        }

        # Обновление существующего config.ini новыми параметрами
        $currentSection = ''
        foreach ($line in $defaultConfig) {
            if ($line -match '^\[(.+)\]$') {
                # Секция
                $currentSection = $matches[1].Trim()
                if (-not $newParams.ContainsKey($currentSection)) {
                    $newParams[$currentSection] = @{}  # Создаем новую секцию, если её нет
                }
            }
            elseif ($line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                # Параметр
                if (-not $newParams[$currentSection].ContainsKey($matches["key"].Trim())) {
                    # Если параметр отсутствует в существующей секции, добавляем его
                    $newParams[$currentSection][$matches["key"].Trim()] = $matches["value"].Trim()
                    Write-Host "Параметр '$($matches["key"].Trim())' добавлен в секцию '$currentSection'."
                }
            }
        }

        # Записываем обновленный файл, сохраняя структуру
        $newConfigContent = @()
        foreach ($section in $newParams.Keys) {
            $newConfigContent += "[$section]"
            foreach ($key in $newParams[$section].Keys) {
                $newConfigContent += "$key=$($newParams[$section][$key])"
            }
            $newConfigContent += ''  # Пустая строка между секциями
        }

        Set-Content -Path $configFilePath -Value $newConfigContent
        Write-Host "Файл конфигурации $configFilePath обновлен."
    }
    try {
        $response = Invoke-RestMethod -Uri $repoUrl
        $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        $latestPreRelease = $response | Where-Object { $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1

        # Определение, какую версию использовать
        $versionInfo = if ($ini.main.update -eq 2) { $latestPreRelease } else { $latestRelease }
        $latestVersion = $versionInfo.tag_name

        $ver = Get-VersionFromScript $fileScript
        if ($ver -eq $latestVersion) {
            return 0  # Скрипт уже обновлен
        }

        $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/$latestVersion.zip"
        Debuging -param_debug $debug -debugmessage ("Update available - " + $latestVersion) -typemessage completed -anyway_log $True
        Update-Module $zipUrl $latestVersion $ini.main.develop
        return 1  # Обновление успешно
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("CATCH- $ModulName - $_") -typemessage warning -anyway_log $True
        return 2  # Ошибка обновления
    }
}
