#!/bin/sh

# ---------- НАСТРОЙКИ ----------
REPO_DIR="/home/listog/Документы/mfua/p/mfua"
UPSTREAM_REMOTE="origin"
UPSTREAM_BRANCH="master"
PUSH_BRANCH="master"

# Токены
TOKEN_LISTOGIT=""


USERNAME_LISTOGIT="ListogGit"
EMAIL_LISTOGIT="listogit@example.com"
# ---------------------------------

cd "$REPO_DIR" || { echo "Ошибка: не удалось перейти в $REPO_DIR"; exit 1; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Ошибка: $REPO_DIR не является Git-репозиторием."
    exit 1
fi

# Устанавливаем локального пользователя (для новых коммитов)
echo "=== Настройка локального пользователя Git для этого репозитория (ListogGit) ==="
git config user.name "$USERNAME_LISTOGIT"
git config user.email "$EMAIL_LISTOGIT"

# Функция для пуша с токеном и поддержкой --force
push_with_token() {
    remote_name="$1"
    username="$2"
    token="$3"
    force="$4"   # если "force", добавим --force

    echo "=== Пушим в $remote_name ($username) ==="
    orig_url=$(git remote get-url "$remote_name" 2>/dev/null)
    if [ -z "$orig_url" ]; then
        echo "Ошибка: remote '$remote_name' не найден."
        return 1
    fi

    case "$orig_url" in
        https://github.com/*)
            path="${orig_url#https://github.com}"
            new_url="https://${username}:${token}@github.com${path}"
            if [ "$force" = "force" ]; then
                echo "Принудительный push (--force) включён."
                git push --force "$new_url" HEAD:"$PUSH_BRANCH"
            else
                git push "$new_url" HEAD:"$PUSH_BRANCH"
            fi
            status=$?
            if [ $status -eq 0 ]; then
                echo "Успешно запушено в $remote_name"
            else
                echo "Ошибка при пуше в $remote_name (код $status)"
            fi
            return $status
            ;;
        *)
            echo "Неподдерживаемый формат URL для remote $remote_name: $orig_url"
            return 1
            ;;
    esac
}

# Основная часть
echo "=== Тянем изменения из $UPSTREAM_REMOTE/$UPSTREAM_BRANCH ==="
git pull "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"
if [ $? -ne 0 ]; then
    echo "Ошибка при git pull. Возможно, конфликты. Скрипт остановлен."
    exit 1
fi
echo "=== Сохраняем локальные изменения ==="
git add .
# Коммитим только если есть что коммитить, чтобы скрипт не падал с ошибкой
if ! git diff-index --quiet HEAD; then
    git commit -m "Автоматический коммит: добавлены новые файлы"
else
    echo "Нет новых файлов для коммита."
fi
# Пушим в newrepo с force (перезаписываем удалённую ветку)
push_with_token "newrepo" "$USERNAME_LISTOGIT" "$TOKEN_LISTOGIT" "force"

echo "=== Скрипт завершён ==="
printf "Нажмите Enter для выхода..."
read dummy
