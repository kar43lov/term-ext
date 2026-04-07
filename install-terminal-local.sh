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
LOCAL_EOF

# ── Подключить в ~/.zshrc.term-ext (перед bindkey) ──────────
MARKER='.zshrc.term-ext-local'
if ! grep -qF "$MARKER" ~/.zshrc.term-ext; then
    # Вставить перед блоком "История: поиск стрелками"
    if grep -q '# ── История: поиск стрелками' ~/.zshrc.term-ext; then
        sed -i.bak '/# ── История: поиск стрелками/i\
# ── Локальные расширения (tmux, claude, ralphex) ─────────────\
[ -f ~/.zshrc.term-ext-local ] \&\& source ~/.zshrc.term-ext-local\
' ~/.zshrc.term-ext
        rm -f ~/.zshrc.term-ext.bak
        info "Подключено в ~/.zshrc.term-ext (перед bindkey)."
    else
        # Fallback: добавить в конец
        echo '' >> ~/.zshrc.term-ext
        echo '[ -f ~/.zshrc.term-ext-local ] && source ~/.zshrc.term-ext-local' >> ~/.zshrc.term-ext
        info "Подключено в конец ~/.zshrc.term-ext."
    fi
else
    info "~/.zshrc.term-ext уже подключает local."
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
