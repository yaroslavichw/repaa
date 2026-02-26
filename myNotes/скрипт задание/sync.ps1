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
    Write-Host "Ошибка при git pull. Скрипт остановлен." -ForegroundColor Red
    exit 1
}

# 4. Копирование содержимого (кроме .git) во второй репозиторий
Write-Host "-> Копирование файлов в $DestRepo..." -ForegroundColor Yellow
Get-ChildItem -Path $SourceRepo | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $DestRepo -Recurse -Force
}

# 5. Отправка изменений второго репозитория на сервер (Push)
Write-Host "-> Фиксация и отправка изменений (Push) из целевого репозитория..." -ForegroundColor Yellow
Set-Location -Path $DestRepo
git add .
$diff = git status --porcelain
if ($diff) {
    git commit -m "Автоматическая синхронизация: обновление файлов из исходного репозитория"
    git push
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Успешный push в целевом репозитории!" -ForegroundColor Green
    } else {
        Write-Host "Ошибка при выполнении git push." -ForegroundColor Red
    }
} else {
    Write-Host "Нет новых изменений для отправки (push)." -ForegroundColor Cyan
}

Write-Host "=== Синхронизация успешно завершена ===" -ForegroundColor Green
Read-Host "Нажмите Enter для выхода..."
