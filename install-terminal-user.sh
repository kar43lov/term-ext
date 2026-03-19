#!/usr/bin/env bash
#
# Разворачивание терминального сетапа для ТЕКУЩЕГО пользователя.
# Без sudo, без влияния на остальных пользователей.
# Всё ставится в ~/.local/bin, конфиги — в ~/
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal-user.sh | bash
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

# ── Проверка: только Linux ────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
    error "Этот скрипт предназначен только для Linux."
    exit 1
fi

# ── Определение архитектуры ───────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_LABEL="x86_64" ;;
    aarch64) ARCH_LABEL="aarch64" ;;
    *)       error "Неподдерживаемая архитектура: $ARCH"; exit 1 ;;
esac

# ── Подготовка директорий ─────────────────────────────────────
mkdir -p ~/.local/bin
mkdir -p ~/.config
mkdir -p ~/.zsh/plugins

# Убедиться, что ~/.local/bin в PATH для текущего скрипта
export PATH="$HOME/.local/bin:$PATH"

info "Установка для пользователя: $(whoami)"
info "Архитектура: $ARCH_LABEL"

# ── Starship ──────────────────────────────────────────────────
if ! command -v starship >/dev/null 2>&1; then
    info "Устанавливаю starship в ~/.local/bin..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
else
    info "starship уже установлен."
fi

# ── fzf ───────────────────────────────────────────────────────
if ! command -v fzf >/dev/null 2>&1; then
    info "Устанавливаю fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish
else
    info "fzf уже установлен."
fi

# ── zoxide ────────────────────────────────────────────────────
if ! command -v zoxide >/dev/null 2>&1; then
    info "Устанавливаю zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
else
    info "zoxide уже установлен."
fi

# ── eza ───────────────────────────────────────────────────────
if ! command -v eza >/dev/null 2>&1; then
    info "Устанавливаю eza в ~/.local/bin..."
    EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
    if [ "$ARCH_LABEL" = "x86_64" ]; then
        EZA_ARCH="x86_64-unknown-linux-gnu"
    else
        EZA_ARCH="aarch64-unknown-linux-gnu"
    fi
    curl -sSfL "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}.tar.gz" | tar xz -C ~/.local/bin/
    chmod +x ~/.local/bin/eza
else
    info "eza уже установлен."
fi

# ── bat ───────────────────────────────────────────────────────
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    info "Устанавливаю bat в ~/.local/bin..."
    BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
    if [ "$ARCH_LABEL" = "x86_64" ]; then
        BAT_ARCH="x86_64-unknown-linux-gnu"
    else
        BAT_ARCH="aarch64-unknown-linux-gnu"
    fi
    curl -sSfL "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${BAT_ARCH}.tar.gz" | tar xz --strip-components=1 -C /tmp/ "bat-v${BAT_VERSION}-${BAT_ARCH}/bat"
    mv /tmp/bat ~/.local/bin/bat
    chmod +x ~/.local/bin/bat
else
    info "bat уже установлен."
fi

# ── broot ─────────────────────────────────────────────────────
if ! command -v broot >/dev/null 2>&1; then
    info "Устанавливаю broot в ~/.local/bin..."
    if [ "$ARCH_LABEL" = "x86_64" ]; then
        curl -sSfL "https://dystroy.org/broot/download/x86_64-linux/broot" -o ~/.local/bin/broot
    else
        curl -sSfL "https://dystroy.org/broot/download/aarch64-linux/broot" -o ~/.local/bin/broot
    fi
    chmod +x ~/.local/bin/broot
    # --install интерактивный — создаём launcher вручную
    mkdir -p ~/.local/share/broot/launcher/bash
    cat > ~/.local/share/broot/launcher/bash/1 << 'BROOT_LAUNCHER'
#!/bin/bash
function br {
    local cmd cmd_file code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" "$@"; then
        cmd=$(<"$cmd_file")
        command rm -f "$cmd_file"
        eval "$cmd"
    else
        code=$?
        command rm -f "$cmd_file"
        return "$code"
    fi
}
BROOT_LAUNCHER
    mkdir -p ~/.config/broot/launcher/bash
    ln -sf ~/.local/share/broot/launcher/bash/1 ~/.config/broot/launcher/bash/br
else
    info "broot уже установлен."
fi

# ── fzf-tab ───────────────────────────────────────────────────
FZF_TAB_DIR="$HOME/.zsh/plugins/fzf-tab"
if [ ! -d "$FZF_TAB_DIR" ]; then
    info "Устанавливаю fzf-tab..."
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
else
    info "fzf-tab уже установлен."
fi

# ── Конфигурация starship ─────────────────────────────────────
info "Записываю конфигурацию starship..."
cat > ~/.config/starship.toml << 'STARSHIP_EOF'
add_newline = false

[character]
success_symbol = "➜"
error_symbol = "✗"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = "🌱 "

[git_status]
style = "bold yellow"

[cmd_duration]
min_time = 500
format = "⏱ $duration "
STARSHIP_EOF

# ── Конфигурация broot ───────────────────────────────────────
info "Записываю конфигурацию broot..."
mkdir -p ~/.config/broot/skins

cat > ~/.config/broot/conf.hjson << 'BROOT_CONF_EOF'
show_selection_mark: true
content_search_max_file_size: 10MB
enable_kitty_keyboard: false
lines_before_match_in_preview: 1
lines_after_match_in_preview: 1
special_paths: {
    "/media" : {
        list: "never"
        sum: "never"
    }
    "~/.config": { "show": "always" }
}
preview_transformers: []
imports: [
    verbs.hjson
    {
        luma: [
            dark
            unknown
        ]
        file: skins/dark-blue.hjson
    }
    {
        luma: light
        file: skins/white.hjson
    }
]
BROOT_CONF_EOF

cat > ~/.config/broot/verbs.hjson << 'BROOT_VERBS_EOF'
verbs: [
    {
        invocation: edit
        shortcut: e
        key: ctrl-e
        apply_to: text_file
        execution: "$EDITOR {file}"
        leave_broot: false
    }
    {
        invocation: create {subpath}
        execution: "$EDITOR {directory}/{subpath}"
        leave_broot: false
    }
    {
        invocation: git_diff
        shortcut: gd
        leave_broot: false
        execution: "git difftool -y {file}"
    }
    {
        invocation: "backup {version}"
        key: ctrl-b
        leave_broot: false
        auto_exec: false
        execution: "cp -r {file} {parent}/{file-stem}-{version}{file-dot-extension}"
    }
    {
        invocation: terminal
        key: ctrl-t
        execution: "$SHELL"
        set_working_dir: true
        leave_broot: false
    }
]
BROOT_VERBS_EOF

cat > ~/.config/broot/skins/dark-blue.hjson << 'BROOT_SKIN_EOF'
skin: {
    default: gray(22) none  / gray(20) none
    tree: gray(8) None  / gray(4) None
    parent: gray(18) None  / gray(13) None
    file: gray(22) None  / gray(15) None
    directory: ansi(110) None bold / ansi(110) None
    exe: Cyan None
    link: Magenta None
    pruning: gray(12) None Italic
    perm__: gray(5) None
    perm_r: ansi(94) None
    perm_w: ansi(132) None
    perm_x: ansi(65) None
    owner: ansi(138) None
    group: ansi(131) None
    count: ansi(138) gray(4)
    dates: ansi(66) None
    sparse: ansi(214) None
    content_extract: ansi(29) None
    content_match: ansi(34) None
    device_id_major: ansi(138) None
    device_id_sep: ansi(102) None
    device_id_minor: ansi(138) None
    git_branch: ansi(178) None
    git_insertions: ansi(28) None
    git_deletions: ansi(160) None
    git_status_current: gray(5) None
    git_status_modified: ansi(28) None
    git_status_new: ansi(94) None bold
    git_status_ignored: gray(17) None
    git_status_conflicted: ansi(88) None
    git_status_other: ansi(88) None
    selected_line: None gray(6)  / None gray(4)
    char_match: Green None
    file_error: Red None
    flag_label: gray(15) gray(2)
    flag_value: ansi(178) gray(2) bold
    input: White gray(2)  / gray(15) None
    status_error: gray(22) ansi(124)
    status_job: ansi(220) gray(5)
    status_normal: gray(20) gray(4)  / gray(2) gray(2)
    status_italic: ansi(178) gray(4)  / gray(2) gray(2)
    status_bold: ansi(178) gray(4) bold / gray(2) gray(2)
    status_code: ansi(229) gray(4)  / gray(2) gray(2)
    status_ellipsis: gray(19) gray(1)  / gray(2) gray(2)
    purpose_normal: gray(20) gray(2)
    purpose_italic: ansi(178) gray(2)
    purpose_bold: ansi(178) gray(2) bold
    purpose_ellipsis: gray(20) gray(2)
    scrollbar_track: gray(7) None  / gray(4) None
    scrollbar_thumb: gray(22) None  / gray(14) None
    help_paragraph: gray(20) None
    help_bold: ansi(178) None bold
    help_italic: ansi(229) None
    help_code: gray(21) gray(3)
    help_headers: ansi(178) None
    help_table_border: ansi(239) None
    preview: gray(20) gray(1)  / gray(18) gray(2)
    preview_title: gray(23) gray(2)  / gray(21) gray(2)
    preview_line_number: gray(12) gray(3)
    preview_separator: gray(5) None
    preview_match: None ansi(29)
    hex_null: gray(8) None
    hex_ascii_graphic: gray(18) None
    hex_ascii_whitespace: ansi(143) None
    hex_ascii_other: ansi(215) None
    hex_non_ascii: ansi(167) None
    staging_area_title: gray(22) gray(2)  / gray(20) gray(3)
    mode_command_mark: gray(5) ansi(204) bold
    good_to_bad_0: ansi(28)
    good_to_bad_1: ansi(29)
    good_to_bad_2: ansi(29)
    good_to_bad_3: ansi(29)
    good_to_bad_4: ansi(29)
    good_to_bad_5: ansi(100)
    good_to_bad_6: ansi(136)
    good_to_bad_7: ansi(172)
    good_to_bad_8: ansi(166)
    good_to_bad_9: ansi(196)
}
syntax_theme: MochaDark
BROOT_SKIN_EOF

# ── .zshrc ────────────────────────────────────────────────────
info "Записываю .zshrc..."

if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d%H%M%S)
    warn "Старый .zshrc сохранён в ~/.zshrc.backup.*"
fi

cat > ~/.zshrc << 'ZSHRC_EOF'
# ── PATH ──────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$PATH"

# ── Completion ────────────────────────────────────────────────
autoload -Uz compinit
compinit

# ── Терминал ──────────────────────────────────────────────────
export TERM=xterm-256color
stty -ixon

# ── fzf ───────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh 2>/dev/null)" || true

# ── История: поиск стрелками ──────────────────────────────────
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# ── Starship prompt ──────────────────────────────────────────
eval "$(starship init zsh)"

# ── Zoxide (умный cd) ────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── fzf-tab (автодополнение через fzf) ──────────────────────
[ -f ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ] && source ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh

# ── Превью папок при cd через fzf-tab ────────────────────────
if command -v eza >/dev/null 2>&1; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'
fi
zstyle ':fzf-tab:*' fzf-flags --preview-window=right:60%

# ── broot ─────────────────────────────────────────────────────
[ -f ~/.config/broot/launcher/bash/br ] && source ~/.config/broot/launcher/bash/br

# ── Алиасы ────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -l'
    alias la='eza -la'
    alias lt='eza --tree --level=2'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi
ZSHRC_EOF

# ── Проверка: есть ли zsh на сервере ─────────────────────────
if ! command -v zsh >/dev/null 2>&1; then
    warn "zsh не установлен на сервере. Попроси администратора: sudo apt install zsh"
    warn "После установки zsh смени шелл: chsh -s \$(which zsh)"
    warn "Или добавь в ~/.bashrc: exec zsh"
else
    # Проверяем текущий шелл
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        # Пробуем chsh (может не сработать без sudo)
        ZSH_PATH=$(command -v zsh)
        if chsh -s "$ZSH_PATH" 2>/dev/null; then
            info "Шелл по умолчанию изменён на zsh."
        else
            # Если chsh не сработал — добавляем exec zsh в .bashrc
            warn "Нет прав на chsh. Добавляю автозапуск zsh в .bashrc..."
            BASHRC_MARKER="# >>> term-ext: auto-start zsh >>>"
            if ! grep -q "$BASHRC_MARKER" ~/.bashrc 2>/dev/null; then
                cat >> ~/.bashrc << 'BASHRC_EOF'

# >>> term-ext: auto-start zsh >>>
if [ -x "$(command -v zsh)" ] && [ "$(basename "$SHELL")" != "zsh" ]; then
    exec zsh -l
fi
# <<< term-ext: auto-start zsh <<<
BASHRC_EOF
                info "Добавлено в .bashrc: автоматический запуск zsh."
            fi
        fi
    else
        info "Шелл уже zsh."
    fi
fi

echo ""
info "Готово! Установлено (всё в ~/.local/bin):"
echo "  - starship (prompt)"
echo "  - fzf (fuzzy search)"
echo "  - fzf-tab (автодополнение)"
echo "  - zoxide (умный cd)"
echo "  - eza (красивый ls)"
echo "  - bat (красивый cat)"
echo "  - broot (файловый менеджер)"
echo ""
info "Перезапусти шелл:"
echo "  exec zsh"
