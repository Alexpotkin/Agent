function global:Update {
    <#
    Returns:
    1 - Update successful
    2 - Error update
    0 - Script is already up-to-date
    #>
    param($ini)
    $ModulName = "module-Update"
    $fileScript = ".\script.ps1"
    $repoUrl = "https://api.github.com/repos/Alexpotkin/Agent/releases"
    
    try {
        $response = Invoke-RestMethod -Uri $repoUrl
        $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        $latestPreRelease = $response | Where-Object { $_.prerelease } | Sort-Object -Property published_at -Descending | Select-Object -First 1
        
        # Determine the installation URL based on the value of $ini.main.update
        write-host ($latestVersion)
        if ($ini.main.update -eq 2) {
            $latestVersion = $latestPreRelease.tag_name
            if ($ver -eq $latestVersion) {
                return  $updateResult = 0
            }
            Debugging -param_debug $debug -debugmessage ("Experimental version found - " + $latestVersion) -typemessage completed -anyway_log $True
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestPreRelease.tag_name + ".zip"
            if (-not ($zipUrl -match "^https?://")) {
                throw "URL is not valid!"
                return $updateResult = 2  #error
            }
            else {
                Debugging -param_debug $debug -debugmessage ("Path to the pre-release version file: " + $zipUrl) -typemessage completed -anyway_log $true
            }
        }
        else {
            $latestVersion = $latestRelease.tag_name
            if ($ver -eq $latestVersion) {
                return  $updateResult = 0
            }
            Debugging -param_debug $debug -debugmessage ("Update available - " + $latestVersion) -typemessage completed -anyway_log $True
            $zipUrl = "https://github.com/Alexpotkin/Agent/archive/refs/tags/" + $latestRelease.tag_name + ".zip"
            if (-not ($zipUrl -match "^https?://")) {
                throw "URL is not valid!"
                return $updateResult = 2  #error
            }
            else {
                Debugging -param_debug $debug -debugmessage ("Path to the release version file: " + $zipUrl) -typemessage completed -anyway_log $true
            }
        }
        $zipPath = ".\update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
        Remove-Item $zipPath
        if ($ini.main.develop -ne 1) {
            Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination
        }
        $firstLine = Get-Content -Path $fileScript -TotalCount 1
        if ($firstLine -match '(\d+(\.\d+){0,3}\w*)') {
            $updatedVersion = $matches[0]
            if ($latestVersion -eq $updatedVersion) {
                Debugging -param_debug $debug -debugmessage ("Script successfully updated to version" + $updatedVersion)  -typemessage completed -anyway_log $true
                Remove-Item ".\temp" -Recurse -Force
                if ($ini.main.develop -eq 1) {
                    return $updateResult = 1
                }
                Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination
                return $updateResult = 1
            }
            else {
                Debugging -param_debug $debug -debugmessage ("Script not updated. Current version - " + $updatedVersion)  -typemessage warning -anyway_log $true
                Remove-Item ".\temp" -Recurse -Force
                return $updateResult = 2
            }
        }
        else {
            Debugging -param_debug $debug -debugmessage ("Script header does not contain a version number")  -typemessage completed -anyway_log $true
        }
        return $updateResult = 2
        
    }
    catch {
        Debugging -param_debug $debug -debugmessage ("CATCH-($ModulName) $_ ") -typemessage warning -anyway_log $True
        return $updateResult = 2
    }
}
