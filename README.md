# dotfiles

個人開発環境の設定ファイル群。各ディレクトリを、対応する設定先へ **symlink** で展開して使う。

想定環境: WSL2 (Debian) を主とする Linux。

> **前提**: アイコンを含む UI を正しく表示するため、[Nerd Font](https://www.nerdfonts.com/) を端末に導入し、ターミナルの表示フォントに設定しておくこと。

## 構成

```
dotfiles/
├── install.sh     必要なコマンド類の導入スクリプト（dotfiles-setup として再利用可）
├── nvim/          Neovim 設定（lazy.nvim ベース・Python 開発向け）→ ~/.config/nvim
├── starship/      Starship プロンプト設定（Dracula 配色・二段組・Nerd Font アイコン）→ ~/.config/starship.toml
├── claude/        Claude Code 設定（CLAUDE.md / settings / hooks / skills / output-styles）→ ~/.claude 配下
├── ccstatusline/  ccstatusline 設定（Claude Code のステータスライン）→ ~/.config/ccstatusline/settings.json
├── bash/          bash 設定（bashrc・starship 初期化の TTY ガード）→ ~/.bashrc
├── git/           Git 設定（gitconfig）→ ~/.gitconfig
└── gh/            GitHub CLI 設定（config.yml）→ ~/.config/gh/config.yml
```

## nvim

[lazy.nvim](https://github.com/folke/lazy.nvim) によるプラグイン管理。ディレクトリごと `~/.config/nvim` へ symlink する。

```
nvim/
├── init.lua                  エントリポイント
├── lazy-lock.json            プラグインのバージョンロック
└── lua/
    ├── base.lua              基本オプション
    ├── keymaps.lua           キーマップ
    ├── config/
    │   ├── lazy.lua          lazy.nvim ブートストラップ
    │   └── lsp.lua           LSP 設定
    └── plugins/                     プラグインごとの spec
        ├── autopairs.lua            括弧の自動ペアリング
        ├── bufferline.lua           バッファのタブ風表示
        ├── claudecode.lua           Claude Code nvim 連携
        ├── commentary.lua           コメントアウト
        ├── completion.lua           補完
        ├── conform.lua              フォーマッタ
        ├── dracula.lua              カラースキーム（Dracula）
        ├── dropbar.lua              winbar パンくずリスト
        ├── flash.lua                ジャンプ・検索ナビゲーション
        ├── fzf-lua.lua              ファジーファインダー
        ├── gitsigns.lua             Git 変更のサイン表示
        ├── lualine.lua              ステータスライン
        ├── noice.lua                コマンドライン（Ex）の中央ポップアップ表示
        ├── oil.lua                  バッファとして編集するファイラ
        ├── orgmode.lua              Org-mode
        ├── render-markdown.lua      Markdown のインライン描画
        ├── surround.lua             囲み文字の操作
        ├── toggleterm.lua           端末トグル（浮き窓）
        ├── tree-sitter-manager.lua  シンタックスハイライト（treesitter）
        ├── which-key.lua            キーバインドのヒント表示
        └── winresizer.lua           ウィンドウリサイズ
```

各プラグインの使い方（コメントアウトの [vim-commentary](https://github.com/tpope/vim-commentary) など）は [`nvim/README.md`](nvim/README.md) にまとめてある。

展開（`~/.config/nvim` への symlink）は `install.sh` が行う（「セットアップ」を参照）。

### Python 開発の前提

- Python のツール類（ruff・pyright など）は [uv](https://github.com/astral-sh/uv) で global に導入する。Debian 素の python は `ensurepip` を欠き、pip / Mason 経由の導入が失敗するため。
- LSP はプロジェクトの venv を検出して利用する。プロジェクトごとに venv を用意しておく。

## starship

[Starship](https://starship.rs/) のプロンプト設定。Dracula 配色の二段組で、Git ブランチや言語ランタイム（Python / Node など、環境がある時だけ）を Nerd Font のアイコンで示す。背景色は使わず、文字色とアイコンだけで彩る。ファイル単体を `~/.config/starship.toml` へ symlink する（`install.sh` が行う）。

> アイコンの表示には **Nerd Font 版**のフォント（例: `JetBrainsMono Nerd Font`）を端末の表示フォントに設定すること。素の `JetBrains Mono` ではアイコンが表示されない。

## claude

[Claude Code](https://claude.com/claude-code) の共有可能な設定（`CLAUDE.md` / `settings.json` / フック / スキル / 出力スタイル）。`~/.claude` 配下には認証情報や履歴が同居するため館ごとは symlink せず、必要なファイルだけを個別に結ぶ（`install.sh` が行う）。

詳細は [`claude/README.md`](claude/README.md) を参照。

## ccstatusline

[ccstatusline](https://www.npmjs.com/package/ccstatusline) による Claude Code のステータスライン表示の設定。二段組で、1 段目にモデル名・コンテキスト使用率・セッション使用量・週次使用量・Git ブランチ、2 段目にセッションと週次それぞれのリセットまでの残り時間・時刻（`HH:MM`）を区切り付きで並べる。ステータスライン本体は `claude/settings.json` の `statusLine` から呼び出される（本体の導入手順は [`claude/README.md`](claude/README.md) を参照）。ファイル単体を `~/.config/ccstatusline/settings.json` へ symlink する（`install.sh` が行う）。

## bash

bash の設定（`~/.bashrc`）。ファイル単体を `~/.bashrc` へ symlink する（`install.sh` が行う）。starship の初期化と keychain（ssh-agent）の起動は、いずれも対話端末（TTY）でのみ働くようガードしてある。`bash -i` をパイプ出力で起こすツール（Claude Code など）に、starship の precmd / preexec が吐くエスケープが混入したり、keychain がパスフレーズ入力で止まったりするのを防ぐため。

あわせて `claude` を同名の関数で包み、起動時のモデルに応じて `--effort` を補う。Claude Code の `effortLevel` は単一の値で、しかもセッション開始時にしか読まれないため、モデル別に分けるには起動時に渡すほかない。opus 5 なら `xhigh`、fable 5 なら `high`。有効なモデルは `--model` 引数 → `ANTHROPIC_MODEL` → `claude/settings.json` の `model` の順に探し、明示の `--effort` と `claude mcp` などの副コマンドには手を触れない。非対話シェルではこの bashrc が冒頭で `return` するため、フックやスクリプトが呼ぶ `claude` は素の実体のまま。

## git

Git の設定（`~/.gitconfig`）。ファイル単体を `~/.gitconfig` へ symlink する（`install.sh` が行う）。

## gh

[GitHub CLI](https://cli.github.com/) の設定（`config.yml`）。ファイル単体を `~/.config/gh/config.yml` へ symlink する（`install.sh` が行う）。`gh` 本体の導入も `install.sh` が公式 apt リポジトリ経由で行う。

## コマンドの導入

設定が前提とするコマンド類の導入と、各設定の symlink 展開を、`install.sh` で一括して行える。**冪等**で、既に入っているもの・結び済みのものは skip するため、再実行して差し支えない。

```bash
bash ~/dotfiles/install.sh            # コマンド導入 + symlink 展開
bash ~/dotfiles/install.sh --no-apt   # sudo apt を使う段を飛ばす
```

導入されるもの:

- apt: `git` / `curl` / `unzip` / `build-essential`（treesitter のビルド用）/ `keychain` / `ca-certificates` / `bubblewrap` / `socat`（Claude Code sandbox 用）/ `ripgrep`（fzf-lua の live grep 用）/ `shfmt`（シェルスクリプトフォーマッタ）/ `poppler-utils`・`pandoc`・`tesseract-ocr`・`tesseract-ocr-jpn`（PDF の抽出・変換・日本語 OCR）/ `man-db`（man と apropos。Debian の最小構成には入っていない）
- `nvim`（公式 tarball。Debian 素の apt 版は古く `vim.uv` を満たさないため）
- `uv`（Python ツールチェーン）・`bun`（JS ツールチェーン）・`starship`（プロンプト）
- `fzf`（`~/.fzf.bash` を生成。`--no-update-rc` で bashrc は触らない）
- Claude Code 本体（`bun install -g @anthropic-ai/claude-code`）
- `basedpyright` / `ruff`（`uv tool install`）・`ccstatusline`（`bun install -g`）
- `stylua`（Lua フォーマッタ。GitHub Releases から `~/.local/bin` へ導入）
- `gh`（GitHub CLI。公式 apt リポジトリ経由。`--no-apt` 時は skip）

導入に続けて、**symlink を展開**する。`bash/bashrc`→`~/.bashrc`、`starship/starship.toml`→`~/.config/starship.toml`、`nvim`→`~/.config/nvim`、`ccstatusline/settings.json`→`~/.config/ccstatusline/settings.json`、`git/gitconfig`→`~/.gitconfig`、`gh/config.yml`→`~/.config/gh/config.yml`、`claude/` の設定・フック・出力スタイル・スキルを `~/.claude` 配下へ、それぞれ結ぶ。展開先に実体ファイルがある場合は `.bak.<epoch>` へ退避してから結ぶため、上書きで失われることはない。`~/.claude` は認証情報や履歴が同居するため館ごとは結ばず、必要なファイルだけを個別に結ぶ。

さらに MCP サーバー `pdf-mcp` を `claude mcp add-json --scope user` で user スコープへ登録する（登録済みなら skip するため冪等）。

さらに末尾で、自らを `~/.local/bin/dotfiles-setup` へ symlink する。以降はどこからでも `dotfiles-setup`（または `dotfiles-setup --no-apt`）の一声で再実行できる。

> **Nerd Font** は端末（WSL なら Windows 側）の表示フォント設定であり、`install.sh` の管轄外。別途導入すること。

## セットアップ

clone して `install.sh` を一度走らせれば、コマンド導入と symlink 展開がともに済む。冪等なので再実行も安全。

```bash
git clone git@github.com:autre-temps/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh            # コマンド導入 + symlink 展開
```

個別の展開先や退避（`.bak`）の挙動は「コマンドの導入」を参照。
