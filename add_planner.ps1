$script_dir = $PSScriptRoot
Write-Output $script_dir
Set-Location -Path $script_dir
$actionScriptPath = ($script_dir +"\"+"script.vbs")
$path1 = $ExecutionContext.SessionState.Path.CurrentLocation.Path + "\"
if ($null -eq $global:taskName) {
    $global:taskName = "script_telegram"
}
Write-Host "проверка наличия прав администратора..."
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList $PSCommandPath -Verb RunAs
    break
}
else {
    $time = New-TimeSpan -Minutes 5
    # Проверяем, установлен ли модуль ScheduledTasks
        if (-not (Get-Module -ListAvailable -Name ScheduledTasks)) {
            Write-Host "Модуль ScheduledTasks не найден. Установите его с помощью Install-Module -Name ScheduledTasks -Scope CurrentUser -Force"
        }

    # Создание задания
    $task = New-ScheduledTask -Action (New-ScheduledTaskAction -Execute "$actionScriptPath" -WorkingDirectory("$path1"))  -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $time)

    # Регистрация задания в планировщике
    Register-ScheduledTask -TaskName $global:taskName  -TaskPath "\" -InputObject $task -User "SYSTEM"
    }