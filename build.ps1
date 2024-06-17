$folderPath = ".\build"
$filesToClear = @("ID.txt", "code.txt")
$fileToRename = ".\config_build.ini"
$newFileName = "config.ini"
$zipFilePath = ".\build.zip"
# Проверка существования папки 'build'
if (-not (Test-Path $folderPath)) {
	New-Item -ItemType Directory -Path $folderPath
	Write-Host "Папка 'build' была успешно создана."
}
else {
	Get-ChildItem $folderPath | Remove-Item -Force -Recurse
	Write-Host "Папка 'build' была успешно очищена."
}

# Копирование файлов и папок
$sourceFiles = @(".\add_planner.ps1", ".\code.txt", ".\config_build.ini", ".\ID.txt", ".\README.txt", ".\script.bat", ".\script.ps1", ".\script.vbs")  # Список файлов для копирования
$sourceFolders = @(".\components", ".\cobian")     # Список папок для копирования

foreach ($file in $sourceFiles) {
	Copy-Item -Path $file -Destination $folderPath
	Write-Host "Файл '$file' был скопирован в папку 'build'."
}

foreach ($folder in $sourceFolders) {
	Copy-Item -Path $folder -Destination $folderPath -Recurse
	Write-Host "Папка '$folder' была скопирована в папку 'build'."
}

# Очистка файлов ID.txt и code.txt
foreach ($fileToClear in $filesToClear) {
	$filePath = Join-Path -Path $folderPath -ChildPath $fileToClear
	Set-Content -Path $filePath -Value ""
	Write-Host "Файл '$fileToClear' был успешно очищен."
}
# Переименование файла config_build.ini в config.ini
$oldFilePath = Join-Path -Path $folderPath -ChildPath $fileToRename
$newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
Rename-Item -Path $oldFilePath -NewName $newFileName
Write-Host "Файл 'config_build.ini' был успешно переименован в 'config.ini'."

# Удалить существующий zip-архив, если он существует
if (Test-Path $zipFilePath) {
	Remove-Item $zipFilePath -Force
	Write-Host "Cуществующий zip-архив был удален."
}

# Создание нового zip-архива
Compress-Archive -Path $folderPath -DestinationPath $zipFilePath
Write-Host "Папка 'build' была успешно упакована в новый zip-архив '$zipFilePath'."