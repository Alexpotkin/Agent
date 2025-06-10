function global:Update {
    <#
    Скрипт описание
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
    $defaultConfigFilePath = ".\default_config.ini"  # новый путь к шаблону конфигурации

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

        # Считываем существующий конфигурационный файл
        $existingConfig = Get-Content -Path $configFilePath
        $newParams = @{}

        # Считываем новый конфигурационный файл по умолчанию
        $defaultConfig = Get-Content -Path $defaultConfigFilePath

        # Извлекаем существующие параметры
        foreach ($line in $existingConfig) {
            if ($line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                $newParams[$matches["key"].Trim()] = $matches["value"].Trim()
            }
        }

        # Обновление существующего config.ini новыми параметрами
        foreach ($line in $defaultConfig) {
            if ($line -match '^(?<key>[^=]+)=(?<value>.*)$') {
                $key = $matches["key"].Trim()
                $value = $matches["value"].Trim()

                # Если параметр отсутствует в существующем файле, добавляем его
                if (-not $newParams.ContainsKey($key)) {
                    $newParams[$key] = $value
                    Write-Host "Параметр '$key' добавлен в конфигурационный файл."
                }
            }
        }

        # Запись обновленного файла
        $newConfigContent = $newParams.GetEnumerator() | Sort-Object Name | ForEach-Object {
            "$($_.Key)=$($_.Value)"
        }

        Set-Content -Path $configFilePath -Value $newConfigContent
        Write-Host "Файл конфигурации $configFilePath обновлен."
    }

    try {
        $response = Invoke-RestMethod -Uri $repoUrl
        $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        $latestPreRelease = $response | Where-Object { $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1

        # Determine which version to use
        $versionInfo = if ($ini.main.update -eq 2) { $latestPreRelease } else { $latestRelease }
        $latestVersion = $versionInfo.tag_name

        $ver = Get-VersionFromScript $fileScript
        if ($ver -eq $latestVersion) {
            return 0  # Script is already up-to-date
        }

        $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/$latestVersion.zip"
        Debuging -param_debug $debug -debugmessage ("Update available - " + $latestVersion) -typemessage completed -anyway_log $True

        Update-Module $zipUrl $latestVersion $ini.main.develop
        Update-ConfigFile -configFilePath $configFilePath -defaultConfigFilePath $defaultConfigFilePath  # Обновление конфигурации

        return 1  # Update successful
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("CATCH- $ModulName - $_") -typemessage warning -anyway_log $True
        return 2  # Error update
    }
}
