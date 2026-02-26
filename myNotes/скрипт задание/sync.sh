#!/bin/bash

# ---------- НАСТРОЙКИ ----------
SOURCE_REPO="/home/listog/Документы/mfua/p/mfua"
DEST_REPO="/home/listog/Документы/mfua/p/new_repo"
REMOTE_NAME="origin"
BRANCH_NAME="master"
# ---------------------------------

echo "=== Запуск синхронизации репозиториев ==="

# 1. Проверка существования путей
if [ ! -d "$SOURCE_REPO" ]; then
    echo "Ошибка: Исходная папка $SOURCE_REPO не найдена."
    exit 1
fi

if [ ! -d "$DEST_REPO" ]; then
    echo "Ошибка: Целевая папка $DEST_REPO не найдена."
    exit 1
fi

# 2. Переход в исходный репозиторий
cd "$SOURCE_REPO" || exit 1
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Ошибка: $SOURCE_REPO не является Git-репозиторием."
    exit 1
fi

# 3. Синхронизация с удалённой копией
echo "-> Тянем изменения из $REMOTE_NAME/$BRANCH_NAME..."
git pull "$REMOTE_NAME" "$BRANCH_NAME"
if [ $? -ne 0 ]; then
    echo "Ошибка при git pull. Скрипт остановлен."
    exit 1
fi

# 4. Копирование содержимого (кроме .git) во второй репозиторий
echo "-> Копирование файлов в $DEST_REPO..."
rsync -av --exclude='.git' "$SOURCE_REPO/" "$DEST_REPO/"

# 5. Отправка изменений второго репозитория на сервер (Push)
echo "-> Фиксация и отправка изменений (Push) из целевого репозитория..."
cd "$DEST_REPO" || exit 1
git add .
if ! git diff-index --quiet HEAD; then
    git commit -m "Автоматическая синхронизация: обновление файлов из исходного репозитория"
    git push
    if [ $? -eq 0 ]; then
        echo "Успешный push в целевом репозитории!"
    else
        echo "Ошибка при выполнении git push."
    fi
else
    echo "Нет новых изменений для отправки (push)."
fi

echo "=== Синхронизация успешно завершена ==="
printf "Нажмите Enter для выхода..."
read dummy
