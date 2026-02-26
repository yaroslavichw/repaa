# ---------- НАСТРОЙКИ ----------
$SourceRepo = "C:\Path\To\Your\SourceRepo"
$DestRepo   = "C:\Path\To\Your\DestRepo"
$RemoteName = "origin"
$BranchName = "master"
# ---------------------------------

Write-Host "=== Запуск синхронизации репозиториев ===" -ForegroundColor Cyan

# 1. Проверка существования путей
if (-Not (Test-Path -Path $SourceRepo)) {
    Write-Host "Ошибка: Исходная папка $SourceRepo не найдена." -ForegroundColor Red
    exit 1
}

if (-Not (Test-Path -Path $DestRepo)) {
    Write-Host "Ошибка: Целевая папка $DestRepo не найдена." -ForegroundColor Red
    exit 1
}

# 2. Переход в исходный репозиторий
Set-Location -Path $SourceRepo
$gitCheck = git rev-parse --git-dir 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка: $SourceRepo не является Git-репозиторием." -ForegroundColor Red
    exit 1
}

# 3. Синхронизация с удалённой копией
Write-Host "-> Тянем изменения из $RemoteName/$BranchName..." -ForegroundColor Yellow
git pull $RemoteName $BranchName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка при git pull. Возможно, конфликты. Скрипт остановлен." -ForegroundColor Red
    exit 1
}

# 4. Копирование содержимого (кроме .git) во второй репозиторий
Write-Host "-> Копирование файлов в $DestRepo..." -ForegroundColor Yellow
# Получаем все элементы в корне, кроме .git, и копируем их с перезаписью (-Force)
Get-ChildItem -Path $SourceRepo | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $DestRepo -Recurse -Force
}

Write-Host "=== Синхронизация успешно завершена ===" -ForegroundColor Green
Read-Host "Нажмите Enter для выхода..."
