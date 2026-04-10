#!/usr/bin/env bash
#
# Локальные расширения для личных машин (tmux, claude, ralphex).
# Дополнение к term-ext — ставится после основного скрипта.
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal-local.sh | bash
#
set -euo pipefail

# ── Цвета ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# ── Проверка: term-ext установлен? ───────────────────────────
if [ ! -f ~/.zshrc.term-ext ]; then
    error "term-ext не установлен. Сначала выполни:"
    echo "  curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal.sh | bash"
    exit 1
fi

# ── Определение ОС ───────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Linux)  OS_TYPE="linux" ;;
    Darwin) OS_TYPE="macos" ;;
    *)      error "Неподдерживаемая ОС: $OS"; exit 1 ;;
esac

info "ОС: $OS_TYPE"

# ── Записываем ~/.zshrc.term-ext-local ───────────────────────
info "Записываю ~/.zshrc.term-ext-local..."

cat > ~/.zshrc.term-ext-local << 'LOCAL_EOF'
# ══════════════════════════════════════════════════════════════
# term-ext-local: персональные расширения (tmux, claude, ralphex)
# Обновляется скриптом install-terminal-local.sh
# ══════════════════════════════════════════════════════════════

# ── macOS: Homebrew PATH ─────────────────────────────────────
if [[ "$(uname -s)" == "Darwin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# ── tmux утилиты ─────────────────────────────────────────────
if command -v tmux >/dev/null 2>&1; then
    alias ta='tmux attach-session -t'
    alias tls='tmux list-sessions'
    alias tl='tmux ls'
    alias tk='tmux kill-session -t'

    # ts — интерактивный выбор tmux-сессии через fzf
    ts() {
        local s=$(tmux ls -F "#{session_name} (#{session_windows} win, #{?session_attached,attached,detached})" 2>/dev/null | \
            fzf --prompt="tmux> " --header="Enter: подключиться | Ctrl-D: удалить сессию" \
                --bind "ctrl-d:execute-silent(tmux kill-session -t {1})+reload(tmux ls -F '#{session_name} (#{session_windows} win, #{?session_attached,attached,detached})' 2>/dev/null)" | \
            cut -d" " -f1)
        [ -n "$s" ] && tmux attach -t "$s"
    }
fi

# ── Claude ───────────────────────────────────────────────────
if command -v claude >/dev/null 2>&1; then
    alias cl='claude'

    # tc — запуск claude в tmux
    tc() {
        if [ -n "$TMUX" ]; then
            command claude "$@"
        else
            tmux new-session -s "claude-$(date +%H%M%S)" "claude $*"
        fi
    }
fi

# ── Ralphex ──────────────────────────────────────────────────
if command -v ralphex >/dev/null 2>&1; then
    alias ralph='command ralphex'

    # ralphex — автоматически оборачивает в tmux
    ralphex() {
        if [ -n "$TMUX" ]; then
            command ralphex "$@"
        else
            tmux new-session -s "ralph-$(date +%H%M%S)" "ralphex $*"
        fi
    }
fi

# help-local — шпаргалка по локальным расширениям
help-local() {
    echo ""
    echo "\033[1;36m  term-ext-local — шпаргалка\033[0m"
    echo "\033[90m  ─────────────────────────────────────────\033[0m"
    echo ""
    if command -v tmux >/dev/null 2>&1; then
    echo "\033[1;33m  tmux\033[0m"
    echo "    ts           выбор сессии через fzf (Ctrl-D — удалить)"
    echo "    ta имя       подключиться к сессии"
    echo "    tl / tls     список сессий"
    echo "    tk имя       удалить сессию"
    echo ""
    fi
    if command -v claude >/dev/null 2>&1; then
    echo "\033[1;33m  Claude\033[0m"
    echo "    cl           запуск claude"
    echo "    tc           запуск claude в tmux-сессии"
    echo ""
    fi
    if command -v ralphex >/dev/null 2>&1; then
    echo "\033[1;33m  Ralphex\033[0m"
    echo "    ralph        запуск ralphex напрямую"
    echo "    ralphex      запуск ralphex в tmux-сессии"
    echo ""
    fi
    echo "\033[90m  Полная документация: https://github.com/kar43lov/term-ext\033[0m"
    echo ""
}
LOCAL_EOF

# ── Подключить в ~/.zshrc ─────────────────────────────────────
# Добавляем в .zshrc (не в .zshrc.term-ext), чтобы повторный запуск
# основного скрипта не затирал подключение local.
LOCAL_SOURCE='[ -f ~/.zshrc.term-ext-local ] && source ~/.zshrc.term-ext-local'
if ! grep -qF '.zshrc.term-ext-local' ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "$LOCAL_SOURCE" >> ~/.zshrc
    info "Подключено в ~/.zshrc."
else
    info "~/.zshrc уже подключает local."
fi

echo ""
info "Готово! Добавлены персональные расширения:"
echo "  - tmux: ta, tls, tl, tk, ts (fzf-выбор сессии)"
echo "  - claude: cl, tc (запуск в tmux)"
echo "  - ralphex: ralph, ralphex (запуск в tmux)"
if [ "$OS_TYPE" = "macos" ]; then
    echo "  - Homebrew PATH"
fi
echo ""
info "Применить: exec zsh"
