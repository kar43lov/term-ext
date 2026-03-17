# term-ext

Скрипт для разворачивания терминального сетапа на Linux-сервере одной командой.

## Что устанавливается

- **zsh** — shell
- **starship** — кастомный prompt
- **fzf** — fuzzy search
- **fzf-tab** — автодополнение через fzf
- **zoxide** — умный `cd`
- **eza** — красивый `ls`
- **bat** — красивый `cat`
- **broot** — файловый менеджер

## Использование

### Вариант 1 — через scp

```bash
scp install-terminal.sh user@server:~/
ssh user@server
bash install-terminal.sh
exec zsh
```

### Вариант 2 — одна команда через curl

```bash
curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal.sh | bash
exec zsh
```

## Требования

- Linux (Debian/Ubuntu, Fedora, Arch, Alpine)
- sudo-доступ для установки пакетов
