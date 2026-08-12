#!/bin/bash
# Bootstrap: восстановление конфигов и программ из бэкапа Ri256/bakup
# Запуск на свежей системе (Arch/Manjaro), из-под обычного пользователя:
#   curl -L https://raw.githubusercontent.com/Ri256/bakup/main/setup.sh | bash
set -u

# Должен запускаться из-под ОБЫЧНОГО пользователя (не root!)
if [ "$(id -u)" -eq 0 ]; then
  echo "ОШИБКА: запустите скрипт из-под обычного пользователя, НЕ от root."
  echo "  curl -L https://raw.githubusercontent.com/Ri256/bakup/main/setup.sh | bash"
  exit 1
fi

REPO="https://github.com/Ri256/bakup.git"
BARE="$HOME/.cfg-store.git"

echo "==> 1/5 База (git, curl, base-devel)..."
if ! command -v git >/dev/null; then
  sudo pacman -S --needed --noconfirm git
fi
if ! command -v curl >/dev/null; then
  sudo pacman -S --needed --noconfirm curl
fi
# base-devel нужен для сборки AUR-пакетов (zapret-git и др.)
if ! pacman -Qq base-devel >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm base-devel
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
  MISSING=""
  for p in $(cat "$PKGLIST"); do
    if pacman -Si "$p" >/dev/null 2>&1; then
      PKGS="$PKGS $p"
    else
      MISSING="$MISSING $p"   # AUR / manjaro-only / несуществующие
    fi
  done
  if [ -n "$PKGS" ]; then
    echo "    ставлю: sudo pacman -S --needed --noconfirm$PKGS"
    sudo pacman -S --needed --noconfirm $PKGS
  else
    echo "    (ничего из списка не нашлось)"
  fi
  if [ -n "$MISSING" ]; then
    mkdir -p "$HOME/system"
    echo "    $MISSING" | tr ' ' '\n' | sort -u > "$HOME/system/missing-packages.txt"
    echo "    не найдено пакетов: $(wc -l < "$HOME/system/missing-packages.txt") — список в system/missing-packages.txt"
  fi
fi
if [ -s apps-flatpak.txt ]; then
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "    ставлю flatpak..."
    sudo pacman -S --needed --noconfirm flatpak
  fi
  if command -v flatpak >/dev/null; then
    for a in $(cat apps-flatpak.txt); do
      flatpak install --noninteractive --assumeyes "$a" || true
    done
  fi
fi

echo "==> 5b/5 AUR-пакеты (zapret-git и т.п.)..."
AUR_HELPER=""
for h in yay paru; do command -v "$h" >/dev/null && AUR_HELPER="$h" && break; done
install_aur() { # $1 = пакет
  $AUR_HELPER -S --needed --noconfirm "$1" 2>/dev/null || $AUR_HELPER -S --needed "$1" || true
}
if [ -n "$AUR_HELPER" ]; then
  echo "    используем: $AUR_HELPER"
  install_aur zapret-git
else
  echo "    помощника AUR нет — ставлю yay из AUR..."
  if pacman -Qq base-devel >/dev/null 2>&1; then
    if mkdir -p "$HOME/.config/aur" && git clone --depth=1 https://aur.archlinux.org/yay.git "$HOME/.config/aur/yay" 2>/dev/null; then
      if (cd "$HOME/.config/aur/yay" && makepkg -si --noconfirm) 2>/dev/null; then
        AUR_HELPER=yay
        echo "    yay установлен"
      fi
    fi
  fi
  if [ -z "$AUR_HELPER" ]; then
    echo "    собираю yay вручную не вышло — ставлю paru из [extra]..."
    sudo pacman -S --needed --noconfirm base-devel paru 2>/dev/null || true
    if command -v paru >/dev/null 2>&1; then
      AUR_HELPER=paru
    fi
  fi
  if [ -n "$AUR_HELPER" ]; then
    install_aur zapret-git
  else
    echo "    установите AUR-помощник сами: sudo pacman -S paru; paru -S zapret-git"
  fi
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
echo "  * если нет интернета в терминале: проверьте NetworkManager/enabled"
echo "  * SSH-ключ: ssh-keygen -t ed25519 -f ~/.ssh/github -N '' -C 'ваш@mail.com'"
echo "  * добавить .pub на github.com/settings/keys"
echo "  * переключить remote на SSH:"
echo "      git --git-dir=$BARE --work-tree=$HOME remote set-url origin git@github.com:Ri256/bakup.git"
echo "  * бэкапить: bakup  (или git --git-dir=$BARE --work-tree=$HOME push)"
echo "  * не найденные пакеты (AUR/manjaro-only) — в ~/system/missing-packages.txt"
echo "  * если что-то 'не нашлось': sudo pacman -S paru; paru -S <имя>"