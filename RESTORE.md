# Восстановление на новой системе (Arch)

Все конфиги хранятся в приватном репо: https://github.com/Ri256/bakup

## Быстрый путь — бутстрап-скрипт (ставит всё сам)

```bash
curl -L https://raw.githubusercontent.com/Ri256/bakup/main/setup.sh | bash
```

Скрипт сам: клонирует репо, разложит конфиги, установит пакеты из `apps-pacman.txt`
и flatpak из `apps-flatpak.txt`, скопирует команду `bakup`. Понадобится лишь пароль
`sudo` для установки пакетов.

## Ручной путь — по шагам

### Шаг 1 — установка Arch

1. Загрузитесь с ISO Arch.
2. Запустите `archinstall`:
   - выберите диск, часовой пояс, пароль;
   - Desktop Environment — на ваш вкус (Hyprland/KDE — конфиги придут из бэкапа).
3. После первого входа установите git: `sudo pacman -S --needed git`.

## Шаг 2 — восстановление конфигов

```bash
# клонирование в том же виде, что и было (используется алиас config)
git clone https://github.com/Ri256/bakup.git $HOME/.cfg-store.git

# разложить файлы по домашней папке
git --git-dir=$HOME/.cfg-store.git --work-tree=$HOME checkout
```

Если в новой системе уже есть `.zshrc`, `.gitconfig` и т.п. — сначала отодвиньте их в сторону, чтобы не было конфликта:

```bash
mkdir -p ~/old-config && mv ~/.zshrc ~/.gitconfig ~/old-config/
```

И снова выполните `checkout` выше.

Проверьте `~/.config/` — там появятся папки `hypr`, `i3`, `kate`, `btop`, `htop`, `cava` и файлы KDE (`katerc`, `dolphinrc`, ...).

## Шаг 3 — алиас для дальнейших бэкапов

Добавьте в `~/.zshrc`:

```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg-store.git/ --work-tree=$HOME'
alias bakup='/home/rinas/.local/bin/bakup'   # или установите скрипт в свою систему
```

## Шаг 4 — установка программ

```bash
# список установленных пакетов (Manjaro)
pacman -S --needed $(cat apps-pacman.txt)

# flatpak-приложения
flatpak install -y $(cat apps-flatpak.txt)
```

Не найденные пакеты (некоторые могут быть манджар-specific) — спокойно пропускайте.

## Шаг 5 — SSH-ключ для GitHub

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github -N "" -C "ваш-email@mail.com"
cat ~/.ssh/github.pub
```

Добавьте `.pub` на https://github.com/settings/keys, затем создайте `~/.ssh/config`:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
```

И переключите remote на SSH:

```bash
config remote set-url origin git@github.com:Ri256/bakup.git
config push -u origin main
```

## Резюме

| Задача | Команда |
|---|---|
| Показать свои файлы в репо | `config ls-tree -r --name-only HEAD` |
| Добавить файл | `config add <путь-от-HOME>` |
| Зафиксировать | `config commit -m "сообщение"` |
| Отправить на GitHub | `config push` |
| Авто-синхронизация конфигов | `bakup` (скрипт в `~/.local/bin/bakup`) |