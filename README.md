# term-ext

Скрипт для разворачивания терминального сетапа на Linux-сервере одной командой.

## Что устанавливается

- **starship** — кастомный prompt
- **fzf** — fuzzy search
- **fzf-tab** — автодополнение через fzf
- **zoxide** — умный `cd`
- **eza** — красивый `ls`
- **bat** — красивый `cat`
- **broot** — файловый менеджер

## Два скрипта

| Скрипт | Когда использовать |
|--------|-------------------|
| `install-terminal.sh` | Свой сервер, root-доступ, ставит всё системно |
| `install-terminal-user.sh` | Общий сервер, без sudo, ставит только для текущего пользователя |

## Использование

### Свой сервер (с sudo)

```bash
curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal.sh | bash
exec zsh
```

### Общий сервер (без sudo, только для меня)

```bash
curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal-user.sh | bash
exec zsh
```

## Требования

- Linux (x86_64 или aarch64)
- `install-terminal.sh` — sudo-доступ
- `install-terminal-user.sh` — только git и curl (обычно уже есть)
