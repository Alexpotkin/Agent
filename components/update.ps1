function global:Update {
    <#
    Returns:
    1 - Update successful
    0 - Script version up to date
    2 - Error occurred during update
    #>

    param($ini, $ver)

    $repoUrl = "https://github.com/Alexpotkin/Agent"         # URL GitHub
    $updateSetting = $ini.update                              # Получаем значение из ini файла

    try {
        if ($updateSetting -eq 2) {
            $repoUrlApi = "https://api.github.com/repos/Alexpotkin/Agent/releases"
        }
        else {
            $repoUrlApi = "https://api.github.com/repos/Alexpotkin/Agent/releases/latest"
        }

        $releaseData = Invoke-RestMethod -Uri $repoUrlApi -Method Get

        foreach ($release in $releaseData) {
            if (($updateSetting -eq 2 -and $release.prerelease) -or
                ($updateSetting -ne 2 -and !$release.prerelease)) {
                $latestVersion = $release.tag_name
                
                if ($latestVersion -ne $ver) {
                    Debuging -param_debug $debug -debugmessage ("New version available. LOADING... - ($latestVersion)") -typemessage info -anyway_log $true
                    
                    # Load file
                    $zipUrl = $release.zipball_url
                    $zipPath = ".\update.zip"
                    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
                    Debuging -param_debug $debug -debugmessage ("Loading file: - ($zipUrl)") -typemessage info -anyway_log $true
                    
                    # Unzip
                    Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
                    Remove-Item $zipPath
                    
                    # Update
                    Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination ".\" -Recurse -Force
                    Remove-Item ".\temp" -Recurse -Force

                    return $updateResult = 1
                }
                else {
                    Debuging -param_debug $debug -debugmessage ("Script version is current - ($ver)") -typemessage info -anyway_log $true
                    return $updateResult = 0
                }
            }
        }
    }
    catch {
        return $updateResult = 2
    }
}
