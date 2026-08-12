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
# Полный список (включая зависимости: кодеки, звук, драйвера) — важный,
# т.к. на Arch DE метапакеты НЕ тянут их автоматически, в отличие от Manjaro.
if [ -f apps-pacman-all.txt ]; then
  PKGLIST="apps-pacman-all.txt"
  echo "    использую полный список: $PKGLIST"
else
  PKGLIST="apps-pacman.txt"
  echo "    использую список явных пакетов: $PKGLIST"
fi
if command -v pacman >/dev/null; then
  echo "    делаю список доступных в репозитории пакетов..."
  PKGS=""
  for p in $(cat "$PKGLIST"); do
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

echo "==> 5b/5 AUR-пакеты (zapret-git и т.п.)..."
AUR_HELPER=""
for h in paru yay; do command -v "$h" >/dev/null && AUR_HELPER="$h" && break; done
if [ -n "$AUR_HELPER" ]; then
  for p in zapret-git; do
    echo "    $AUR_HELPER: $p"
    $AUR_HELPER -S --needed --noconfirm "$p" 2>/dev/null || $AUR_HELPER -S --needed "$p" || true
  done
else
  echo "    помощник AUR не найден. Поставьте позже вручную: sudo pacman -S paru; paru -S zapret-git"
fi

echo "==> 5c/5 Восстановление конфига zapret..."
if [ -f "$HOME/system/zapret-config.conf" ] && [ -d /opt/zapret ]; then
  sudo cp -f "$HOME/system/zapret-config.conf" /opt/zapret/config
  DEV=$(ip route 2>/dev/null | awk '/default/{print $5; exit}')
  if [ -n "$DEV" ]; then
    sudo sed -i "s/^IFACE_WAN=.*/IFACE_WAN=\"$DEV\"/" /opt/zapret/config
    echo "    IFACE_WAN установлен на текущий интерфейс: $DEV"
  fi
  if command -v nft >/dev/null; then FWTYPE="nftables"; else FWTYPE="iptables"; fi
  sudo sed -i "s/^FWTYPE=.*/FWTYPE=$FWTYPE/" /opt/zapret/config
  sudo systemctl enable zapret 2>/dev/null || true
  sudo systemctl restart zapret 2>/dev/null || true
  echo "    zapret config восстановлен, сервис перезапущен"
else
  echo "    (нет конфига или zapret не установлен — пропускаю)"
fi

echo "==> 5d/5 Включение сервисов (в Arch это делается ВРУЧНУЮ!)..."
# NetworkManager / dhcpcd — без этого не будет сети после ребута
if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
  sudo systemctl enable --now NetworkManager 2>/dev/null || true
  echo "    NetworkManager включён"
else
  sudo systemctl enable --now dhcpcd 2>/dev/null || true
  echo "    NetworkManager не найден, включён dhcpcd"
fi
# Звук: pipewire-юниты должны быть включены для пользователя
if command -v systemctl --user >/dev/null 2>&1; then
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber 2>/dev/null || true
  echo "    pipewire/звук включены"
fi
# Куки/декорот: указать явно
if ! command -v mimeapps-update >/dev/null 2>&1; then
  echo "    (mimeapps-update нет, это не критично)"
else
  mimeapps-update 2>/dev/null || true
fi
echo "    Systemd-сервисы готовы"

echo ""
echo "Готово! Дальше вручную:"
echo "  * SSH-ключ: ssh-keygen -t ed25519 -f ~/.ssh/github -N '' -C 'ваш@mail.com'"
echo "  * добавить .pub на github.com/settings/keys"
echo "  * переключить remote на SSH:"
echo "      git --git-dir=$BARE --work-tree=$HOME remote set-url origin git@github.com:Ri256/bakup.git"
echo "  * бэкапить: bakup  (или git --git-dir=$BARE --work-tree=$HOME push)"
echo "  * если появится ошибка 'Unit X not found' — проверьте кодеки/звук: sudo pacman -S pipewire wireplumber"