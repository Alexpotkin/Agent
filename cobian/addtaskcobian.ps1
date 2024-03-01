Write-Host "проверка наличия прав администратора..."
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList $PSCommandPath -Verb RunAs
    break
}
else {
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFile = Join-Path $scriptDirectory "MainList.lst"
$destinationFolder = "C:\Program Files (x86)\Cobian Backup 11\db\"
    Write-Host "права администратора есть" -ForegroundColor Green
    if (Test-Path -Path 'C:\Program Files (x86)\Cobian Backup 11\db\Mainlist.lst') {
        Write-Host "файл существует"
        Stop-Service -Name CobianBackup11
        Remove-Item 'C:\Program Files (x86)\Cobian Backup 11\db\MainList.lst'
    }
    else {
        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
    }
    Copy-Item -Path $sourceFile -Destination $destinationFolder -Force
    Start-Service -Name CobianBackup11
}