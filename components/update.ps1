#$ComponentName = "update"
function global:Update {
    # function updater
    param($ini, $ver)
    $repoUrl = "https://github.com/Alexpotkin/Agent"         # URL  GitHub
    try {
        $latestVersion = [System.Net.WebRequest]::Create($repoUrl + "/releases/latest").GetResponse().ResponseUri.AbsoluteUri.Split("/")[-1]
        if (($latestVersion -ne $ver) -and ("" -ne $latestVersion)) {
            Debuging -param_debug $debug -debugmessage ("New version available. LOADING... - ($latestVersion)") -typemessage info -anyway_log $true
            # load file
            $zipUrl = $repoUrl + "/archive/$latestVersion.zip"
            $zipPath = ".\update.zip"
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
            Debuging -param_debug $debug -debugmessage ("Loading file!: -  ($zipUrl)") -typemessage info -anyway_log $true

            # unzip
            Expand-Archive -Path $zipPath -DestinationPath ".\temp" -Force
            Remove-Item $zipPath
    
            # update
            Copy-Item -Path ".\temp\agent-$latestVersion\*" -Destination ".\" -Recurse -Force
            Remove-Item ".\temp" -Recurse -Force
            return $updateResult = 1
        }
        elseif ($latestVersion -eq $ver) {
            Debuging -param_debug $debug -debugmessage ("Script version is current - ($ver)") -typemessage info -anyway_log $true
            return $updateResult = 0
        }
    }
    catch {
        return $updateResult = 2
    }
}
