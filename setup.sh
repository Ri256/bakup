#!/bin/bash
# Bootstrap: восстановление конфигов и программ из бэкапа Ri256/bakup
# Запуск на свежей системе (Arch/Manjaro), из-под обычного пользователя:
#   curl -L https://raw.githubusercontent.com/Ri256/bakup/main/setup.sh | bash
set -u

REPO="https://github.com/Ri256/bakup.git"
BARE="$HOME/.cfg-store.git"

echo "==> 1/5 База (git)..."
if ! command -v git >/dev/null; then
  sudo pacman -S --needed --noconfirm git
fi

echo "==> 2/5 Клонирование бэкапа..."
if [ ! -d "$BARE" ]; then
  git clone "$REPO" "$BARE" || { echo "Ошибка: нет доступа к $REPO"; exit 1; }
fi

cfg() { git --git-dir="$BARE" --work-tree="$HOME" "$@"; }

echo "==> 3/5 Восстановление конфигов..."
if cfg checkout 2>/dev/null; then
  echo "    конфиги разложены"
else
  echo "    найдены конфликты — старые версии убираю в ~/.dotfiles-conflict"
  mkdir -p "$HOME/.dotfiles-conflict"
  cfg ls-files | while IFS= read -r f; do
    if [ -e "$HOME/$f" ] && ! diff -q "$HOME/$f" <(cfg show "HEAD:$f" 2>/dev/null) >/dev/null 2>&1; then
      mkdir -p "$HOME/.dotfiles-conflict/$(dirname "$f")"
      mv -f "$HOME/$f" "$HOME/.dotfiles-conflict/$f"
    fi
  done
  cfg checkout
fi

echo "==> 4/5 Скрипт bakup..."
mkdir -p "$HOME/.local/bin"
cp -f "$HOME/bin/bakup" "$HOME/.local/bin/bakup" 2>/dev/null || true
chmod +x "$HOME/.local/bin/bakup" 2>/dev/null || true

echo "==> 5/5 Установка программ из списков..."
cd "$HOME"
if command -v pacman >/dev/null; then
  echo "    делаю список доступных в репозитории пакетов..."
  PKGS=""
  for p in $(cat apps-pacman.txt); do
    pacman -Si "$p" >/dev/null 2>&1 && PKGS="$PKGS $p"
  done
  if [ -n "$PKGS" ]; then
    echo "    ставлю: sudo pacman -S --needed --noconfirm$PKGS"
    sudo pacman -S --needed --noconfirm $PKGS
  else
    echo "    (ничего из списка не нашлось)"
  fi
fi
if command -v flatpak >/dev/null; then
  for a in $(cat apps-flatpak.txt); do
    flatpak install --noninteractive --assumeyes "$a" || true
  done
fi

echo ""
echo "Готово! Дальше вручную:"
echo "  * SSH-ключ: ssh-keygen -t ed25519 -f ~/.ssh/github -N '' -C 'ваш@mail.com'"
echo "  * добавить .pub на github.com/settings/keys"
echo "  * переключить remote на SSH:"
echo "      git --git-dir=$BARE --work-tree=$HOME remote set-url origin git@github.com:Ri256/bakup.git"
echo "  * бэкапить: bakup  (или git --git-dir=$BARE --work-tree=$HOME push)"