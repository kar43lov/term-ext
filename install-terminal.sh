#!/usr/bin/env bash
#
# Скрипт разворачивания терминального сетапа (Linux + macOS).
# Одна команда — полный сетап: zsh, starship, fzf, zoxide, eza, bat, broot, fzf-tab.
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/kar43lov/term-ext/main/install-terminal.sh | bash
#   или
#   bash install-terminal.sh
#
set -euo pipefail

# ── Цвета для вывода ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# ── Определение ОС ───────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Linux)  OS_TYPE="linux" ;;
    Darwin) OS_TYPE="macos" ;;
    *)      error "Неподдерживаемая ОС: $OS"; exit 1 ;;
esac

info "ОС: $OS_TYPE"

# ── Определение пакетного менеджера ───────────────────────────
detect_pm() {
    if [ "$OS_TYPE" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo "brew"
        else
            echo "unknown"
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

PM=$(detect_pm)

# На macOS без Homebrew — предложить установить
if [ "$OS_TYPE" = "macos" ] && [ "$PM" = "unknown" ]; then
    error "Homebrew не установлен. Установи: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

info "Пакетный менеджер: $PM"

# ── Установка системных пакетов ───────────────────────────────
install_packages() {
    local packages=("$@")
    case "$PM" in
        brew)
            brew install "${packages[@]}" 2>/dev/null || true
            ;;
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y -q "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed "${packages[@]}"
            ;;
        apk)
            sudo apk add --quiet "${packages[@]}"
            ;;
        *)
            error "Неподдерживаемый пакетный менеджер. Установи вручную: ${packages[*]}"
            exit 1
            ;;
    esac
}

# На macOS zsh уже есть, на Linux — ставим
if [ "$OS_TYPE" = "linux" ]; then
    info "Устанавливаю базовые пакеты (zsh, git, curl, unzip)..."
    install_packages zsh git curl unzip
else
    info "macOS: zsh уже встроен."
    install_packages git curl
fi

# ── Starship ──────────────────────────────────────────────────
if ! command -v starship >/dev/null 2>&1; then
    info "Устанавливаю starship..."
    if [ "$PM" = "brew" ]; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
else
    info "starship уже установлен."
fi

# ── fzf ───────────────────────────────────────────────────────
if ! command -v fzf >/dev/null 2>&1 && [ ! -f ~/.fzf/bin/fzf ]; then
    info "Устанавливаю fzf..."
    if [ "$PM" = "brew" ]; then
        brew install fzf
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    fi
else
    info "fzf уже установлен."
fi

# ── zoxide ────────────────────────────────────────────────────
if ! command -v zoxide >/dev/null 2>&1; then
    info "Устанавливаю zoxide..."
    if [ "$PM" = "brew" ]; then
        brew install zoxide
    else
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi
else
    info "zoxide уже установлен."
fi

# ── eza (современная замена ls) ───────────────────────────────
if ! command -v eza >/dev/null 2>&1; then
    info "Устанавливаю eza..."
    case "$PM" in
        brew)
            brew install eza
            ;;
        apt)
            if sudo apt-get install -y -qq eza 2>/dev/null; then
                true
            else
                warn "eza недоступен в репозиториях. Устанавливаю из GitHub..."
                EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
                curl -sSfL "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" | sudo tar xz -C /usr/local/bin/
            fi
            ;;
        dnf)
            sudo dnf install -y -q eza 2>/dev/null || warn "eza недоступен через dnf."
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed eza
            ;;
        *)
            warn "Установи eza вручную: https://github.com/eza-community/eza"
            ;;
    esac
else
    info "eza уже установлен."
fi

# ── bat (улучшенный cat) ──────────────────────────────────────
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    info "Устанавливаю bat..."
    case "$PM" in
        brew)   brew install bat ;;
        apt)    sudo apt-get install -y -qq bat ;;
        dnf)    sudo dnf install -y -q bat ;;
        pacman) sudo pacman -S --noconfirm --needed bat ;;
        *)      warn "Установи bat вручную." ;;
    esac
    # В Debian/Ubuntu бинарник называется batcat — делаем симлинк
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        mkdir -p ~/.local/bin
        ln -sf "$(command -v batcat)" ~/.local/bin/bat
    fi
else
    info "bat уже установлен."
fi

# ── broot ─────────────────────────────────────────────────────
if ! command -v broot >/dev/null 2>&1; then
    info "Устанавливаю broot..."
    if [ "$PM" = "brew" ]; then
        brew install broot
    else
        curl -o /tmp/broot -sSfL "https://dystroy.org/broot/download/x86_64-linux/broot"
        chmod +x /tmp/broot
        sudo mv /tmp/broot /usr/local/bin/broot
    fi
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

# ── lazydocker ────────────────────────────────────────────────
if ! command -v lazydocker >/dev/null 2>&1; then
    info "Устанавливаю lazydocker..."
    if [ "$PM" = "brew" ]; then
        brew install lazydocker
    else
        curl -sSfL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi
else
    info "lazydocker уже установлен."
fi

# ── fzf-tab (плагин для zsh) ─────────────────────────────────
FZF_TAB_DIR="$HOME/.zsh/plugins/fzf-tab"
if [ ! -d "$FZF_TAB_DIR" ]; then
    info "Устанавливаю fzf-tab..."
    mkdir -p "$HOME/.zsh/plugins"
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
else
    info "fzf-tab уже установлен."
fi

# ── Конфигурация starship ─────────────────────────────────────
info "Записываю конфигурацию starship..."
mkdir -p ~/.config
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

# ── Конфигурация term-ext ────────────────────────────────────
# Управляемый конфиг пишется в ~/.zshrc.term-ext
# В ~/.zshrc добавляется source-строка — пользовательские добавки не затираются
info "Записываю ~/.zshrc.term-ext..."

cat > ~/.zshrc.term-ext << 'TERMEXT_EOF'
# ══════════════════════════════════════════════════════════════
# term-ext: управляемый конфиг (обновляется скриптом)
# Не редактируй вручную — добавляй свои настройки в ~/.zshrc
# ══════════════════════════════════════════════════════════════

# ── PATH ──────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$PATH"

# ── История ───────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY

# ── Completion ────────────────────────────────────────────────
autoload -Uz compinit
compinit

# ── Терминал ──────────────────────────────────────────────────
export TERM=xterm-256color
stty -ixon

# ── fzf ───────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh 2>/dev/null)" || true

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

# ── Утилиты ──────────────────────────────────────────────────
mkcd() { mkdir -p "\$1" && cd "\$1" }

# ── Docker (если установлен) ──────────────────────────────────
if command -v docker >/dev/null 2>&1; then
    # Определяем, нужен ли sudo для docker
    if docker ps >/dev/null 2>&1; then
        _DOCKER="docker"
    else
        _DOCKER="sudo docker"
    fi

    alias ld='lazydocker'

    dselect() {
        eval "$_DOCKER ps -a --format '{{.Names}}'" \
        | fzf --preview "eval $_DOCKER ps -a --filter name='^/{}$' --format 'Status: {{.Status}}\nImage: {{.Image}}\nPorts: {{.Ports}}'" \
              --preview-window=right:60%
    }

    dr()   { local t=${1:-$(dselect)}; [ -n "$t" ] && eval "$_DOCKER restart $t"; }
    ds()   { local t=${1:-$(dselect)}; [ -n "$t" ] && eval "$_DOCKER stop $t"; }
    dst()  { local t=${1:-$(dselect)}; [ -n "$t" ] && eval "$_DOCKER start $t"; }
    drm()  { local t=${1:-$(dselect)}; [ -n "$t" ] && eval "$_DOCKER rm -f $t"; }
    dlogs(){ local t=${1:-$(dselect)}; [ -n "$t" ] && eval "$_DOCKER logs -f $t"; }
    dps()  { eval "$_DOCKER ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}'"; }
fi
            \$image"
    }
fi

# ── История: поиск стрелками (в конце, после всех плагинов) ──
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search   # xterm
bindkey "^[OA"  up-line-or-beginning-search  # application mode
bindkey "^[[B" down-line-or-beginning-search  # xterm
bindkey "^[OB"  down-line-or-beginning-search # application mode
TERMEXT_EOF

# Добавить source в .zshrc, если ещё нет
TERMEXT_SOURCE='[ -f ~/.zshrc.term-ext ] && source ~/.zshrc.term-ext'
if [ ! -f ~/.zshrc ] || ! grep -qF '.zshrc.term-ext' ~/.zshrc; then
    # Если .zshrc не существует — создаём с source-строкой
    if [ ! -f ~/.zshrc ]; then
        echo "$TERMEXT_SOURCE" > ~/.zshrc
        info "Создан ~/.zshrc с подключением term-ext."
    else
        # .zshrc есть, но без нашей строки — добавляем в начало
        { echo "$TERMEXT_SOURCE"; echo ""; cat ~/.zshrc; } > ~/.zshrc.tmp
        mv ~/.zshrc.tmp ~/.zshrc
        info "Добавлено подключение term-ext в начало ~/.zshrc."
    fi
else
    info "~/.zshrc уже подключает term-ext."
fi

# ── Сделать zsh дефолтным шеллом ─────────────────────────────
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    ZSH_PATH=$(command -v zsh)
    if [ -n "$ZSH_PATH" ]; then
        # Добавить zsh в /etc/shells, если его там нет
        if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
        info "Меняю шелл по умолчанию на zsh..."
        chsh -s "$ZSH_PATH" || warn "Не удалось сменить шелл. Выполни вручную: chsh -s $ZSH_PATH"
    fi
fi

# ── Файл истории ──────────────────────────────────────────────
touch ~/.zsh_history
chmod 600 ~/.zsh_history

echo ""
info "Готово! Установлено:"
echo "  - zsh + compinit"
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
