#!/usr/bin/env bash
# install.sh — dotfiles が前提とするコマンド類を導入する。
#
# 対象環境: WSL2 (Debian) を主とする Linux。
# symlink の展開そのものは行わない（README.md の「セットアップ」を参照）。
# 冪等: 既に入っているものは skip する。再実行して差し支えない。
#
#   bash install.sh            # すべて導入
#   bash install.sh --no-apt   # sudo apt を使う処理を飛ばす

set -euo pipefail

# --- 体裁 ---------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip() { printf '    \033[2m(skip) %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
has()  { command -v "$1" >/dev/null 2>&1; }

NO_APT=0
[ "${1:-}" = "--no-apt" ] && NO_APT=1

# 当セッション中だけ PATH を通し、後段のインストーラが前段の成果を見えるように。
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

# --- 1. apt パッケージ ---------------------------------------------------
# build-essential: treesitter の :TSUpdate に C コンパイラ/make が要る。
# keychain: bashrc の ssh-agent 管理。
APT_PKGS=(git curl unzip build-essential keychain ca-certificates)
if [ "$NO_APT" -eq 0 ]; then
    missing=()
    for p in "${APT_PKGS[@]}"; do
        dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        log "apt: ${missing[*]} を導入"
        sudo apt-get update -qq
        sudo apt-get install -y "${missing[@]}"
    else
        skip "apt パッケージは充足"
    fi
else
    skip "--no-apt 指定のため apt 処理を省略"
fi

# --- 2. Neovim (>=0.10) --------------------------------------------------
# Debian 素の apt 版は古く、vim.uv / vim.lsp.start を満たさない。公式 tarball を使う。
nvim_ok() {
    has nvim && nvim --version | head -1 \
        | grep -qE 'v(0\.1[0-9]|[1-9][0-9]*\.)'
}
if nvim_ok; then
    skip "nvim $(nvim --version | head -1 | awk '{print $2}')"
else
    log "Neovim を ~/.local へ導入"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/nvim.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    mkdir -p "$HOME/.local"
    rm -rf "$HOME/.local/nvim-linux-x86_64"
    tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HOME/.local/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp"
fi

# --- 3. uv (Python ツールチェーン) --------------------------------------
if has uv; then
    skip "uv $(uv --version | awk '{print $2}')"
else
    log "uv を導入"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# --- 4. bun (JS ツールチェーン) -----------------------------------------
if has bun; then
    skip "bun $(bun --version)"
else
    log "bun を導入"
    curl -fsSL https://bun.sh/install | bash
fi

# --- 5. starship (プロンプト) -------------------------------------------
if has starship; then
    skip "starship $(starship --version | head -1 | awk '{print $2}')"
else
    log "starship を ~/.local/bin へ導入"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

# --- 6. fzf (bashrc が ~/.fzf.bash を source) ---------------------------
if [ -f "$HOME/.fzf.bash" ]; then
    skip "fzf (~/.fzf.bash あり)"
else
    log "fzf を ~/.fzf へ導入"
    [ -d "$HOME/.fzf" ] || git clone --depth 1 https://github.com/junegunn/fzf "$HOME/.fzf"
    # --no-update-rc: bashrc は dotfiles 管理下で既に source 行を持つため触らせない。
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
fi

# --- 7. Claude Code 本体 -------------------------------------------------
if has claude; then
    skip "claude $(claude --version 2>/dev/null | head -1)"
else
    log "Claude Code を bun global へ導入"
    bun install -g @anthropic-ai/claude-code
fi

# --- 8. uv tool: Python の LSP/フォーマッタ ------------------------------
for tool in basedpyright ruff; do
    if uv tool list 2>/dev/null | grep -q "^${tool} "; then
        skip "uv tool: $tool"
    else
        log "uv tool install $tool"
        uv tool install "$tool"
    fi
done

# --- 9. bun global: ccstatusline ----------------------------------------
if has ccstatusline; then
    skip "ccstatusline"
else
    log "bun install -g ccstatusline"
    bun install -g ccstatusline
fi

# --- 任意: win32yank (WSL の nvim クリップボード補強) --------------------
# clipboard=unnamedplus は WSL では clip.exe/powershell.exe で概ね足りるが、
# OS→nvim の貼り付けを確実にするなら win32yank があると堅い。任意導入。
if grep -qi microsoft /proc/version 2>/dev/null && ! has win32yank.exe; then
    warn "win32yank 未導入（任意）。貼り付けが不安定なら winget install win32yank などで導入を。"
fi

# --- 呼び鈴: ~/.local/bin/dotfiles-setup として自身を symlink ------------
# 以降は本体の在処を覚えずとも `dotfiles-setup` の一声で再実行できる。
SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
LINK="$HOME/.local/bin/dotfiles-setup"
if [ "$(readlink -f "$LINK" 2>/dev/null)" = "$SCRIPT" ]; then
    skip "dotfiles-setup (リンク済み)"
else
    log "dotfiles-setup を ~/.local/bin へ設置"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$SCRIPT" "$LINK"
fi

log "完了。以降は dotfiles-setup の一声で再実行できます。"
log "次は README.md の「セットアップ」の symlink 展開を行ってくださいませ。"
