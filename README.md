# 💾 bakup — мои конфиги (dotfiles + программы)

Приватная (нет, теперь уже публичная 😄) копия конфигов Rinas.
Внутри: `.zshrc`, `.gitconfig`, конфиги hyprland/i3/kate/btop/htop/cava,
списки установленных пакетов, скрипты автоматического восстановления.

## Восстановление на новой системе (Arch/Manjaro)

Скопируй и вставь в терминал одну команду:

```bash
curl -L https://raw.githubusercontent.com/Ri256/bakup/main/setup.sh | bash
```

Скрипт сам:
1. клонирует этот репозиторий в `~/.cfg-store.git`;
2. раскладывает конфиги по `$HOME` (конфликты — в `~/.dotfiles-conflict`);
3. ставит все пакеты из `apps-pacman.txt` и flatpak из `apps-flatpak.txt`;
4. кладёт команду `bakup` для дальнейших бэкапов.

Подробная инструкция: см. [RESTORE.md](RESTORE.md).

## Бэкап

```bash
bakup   # добавит изменения, закоммитит с датой и запушит
```

Либо вручную:

```bash
config add <путь-файла>
config commit -m "что изменил"
config push
```

## Лицензия

MIT © 2026 Rinas — бери, меняй, наслаждайся 🙂