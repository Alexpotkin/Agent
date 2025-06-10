function global:Update {
    <#
    Returns:
    1 - Update successful
    2 - Error update
    3 - deweloper MODE
    0 - Script is already up-to-date
    #>
    param($ini)
    $ModulName = "module-Update"
    $fileScript = ".\script.ps1"
    $repoUrl = "https://api.github.com/repos/Alexpotkin/Agent/releases"
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
            return 3 # Script off, deweloper mode
        }
    
        Remove-Item ".\temp" -Recurse -Force
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

        return 1  # Update successful
    }
    catch {
        Debuging -param_debug $debug -debugmessage ("CATCH- $ModulName - $_") -typemessage warning -anyway_log $True
        return 2  # Error update
    }
}
