# term-ext

Скрипт для разворачивания терминального сетапа одной командой (Linux + macOS).

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
| `install-terminal.sh` | Свой сервер / Mac, ставит системно (sudo / brew) |
| `install-terminal-user.sh` | Общий сервер, без sudo, только для текущего пользователя |

## Использование

### Свой сервер или Mac

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

- Linux (x86_64, aarch64) или macOS (Apple Silicon, Intel)
- macOS: Homebrew
- `install-terminal.sh` на Linux: sudo-доступ
- `install-terminal-user.sh` на Linux: только git и curl
