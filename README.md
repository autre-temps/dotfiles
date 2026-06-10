# dotfiles

個人開発環境の設定ファイル群。各ディレクトリを、対応する設定先へ **symlink** で展開して使う。

想定環境: WSL2 (Debian) を主とする Linux。

> **前提**: アイコンを含む UI を正しく表示するため、[Nerd Font](https://www.nerdfonts.com/) を端末に導入し、ターミナルの表示フォントに設定しておくこと。

## 構成

```
dotfiles/
├── nvim/          Neovim 設定（lazy.nvim ベース・Python 開発向け）→ ~/.config/nvim
├── starship/      Starship プロンプト設定（Nord 配色・二段組・Nerd Font アイコン）→ ~/.config/starship.toml
├── claude/        Claude Code 設定（settings / skills / output-styles）→ ~/.claude 配下
├── ccstatusline/  ccstatusline 設定（Claude Code のステータスライン）→ ~/.config/ccstatusline/settings.json
└── bash/          bash 設定（bashrc・starship 初期化の TTY ガード）→ ~/.bashrc
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
    └── plugins/              プラグインごとの spec
        ├── commentary.lua    コメントアウト
        ├── completion.lua    補完
        ├── conform.lua       フォーマッタ
        ├── noice.lua         コマンドライン（Ex）の中央ポップアップ表示
        ├── oil.lua           バッファとして編集するファイラ
        ├── toggleterm.lua    端末トグル（浮き窓）
        ├── treesitter.lua    シンタックスハイライト
        └── winresizer.lua    ウィンドウリサイズ
```

展開:

```bash
ln -s ~/dotfiles/nvim ~/.config/nvim
```

### Python 開発の前提

- Python のツール類（ruff・pyright など）は [uv](https://github.com/astral-sh/uv) で global に導入する。Debian 素の python は `ensurepip` を欠き、pip / Mason 経由の導入が失敗するため。
- LSP はプロジェクトの venv を検出して利用する。プロジェクトごとに venv を用意しておく。

## starship

[Starship](https://starship.rs/) のプロンプト設定。Nord 配色の二段組で、Git ブランチや言語ランタイム（Python / Node など、環境がある時だけ）を Nerd Font のアイコンで示す。背景色は使わず、文字色とアイコンだけで彩る。ファイル単体を `~/.config/starship.toml` へ symlink する。

```bash
ln -sfn ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

> アイコンの表示には **Nerd Font 版**のフォント（例: `JetBrainsMono Nerd Font`）を端末の表示フォントに設定すること。素の `JetBrains Mono` ではアイコンが表示されない。

## claude

[Claude Code](https://claude.com/claude-code) の共有可能な設定（`settings.json` / `/commit` スキル / 出力スタイル）。`~/.claude` 配下には認証情報や履歴が同居するため館ごとは symlink せず、必要なファイルだけを個別に結ぶ。

詳細とファイル単位の展開手順は [`claude/README.md`](claude/README.md) を参照。

```bash
ln -sfn ~/dotfiles/claude/settings.json ~/.claude/settings.json
mkdir -p ~/.claude/output-styles ~/.claude/skills/commit
ln -sfn ~/dotfiles/claude/output-styles/vampire-maid.md ~/.claude/output-styles/vampire-maid.md
ln -sfn ~/dotfiles/claude/skills/commit/SKILL.md ~/.claude/skills/commit/SKILL.md
```

## ccstatusline

[ccstatusline](https://www.npmjs.com/package/ccstatusline) による Claude Code のステータスライン表示の設定。モデル名・コンテキスト使用率・セッション使用量・Git ブランチ・時刻（`HH:MM`）を区切り付きで一行に並べる。ステータスライン本体は `claude/settings.json` の `statusLine` から呼び出される（本体の導入手順は [`claude/README.md`](claude/README.md) を参照）。ファイル単体を `~/.config/ccstatusline/settings.json` へ symlink する。

```bash
mkdir -p ~/.config/ccstatusline
ln -sfn ~/dotfiles/ccstatusline/settings.json ~/.config/ccstatusline/settings.json
```

## bash

bash の設定（`~/.bashrc`）。ファイル単体を `~/.bashrc` へ symlink する。starship の初期化は対話端末（TTY）でのみ働くようガードしてある。`bash -i` をパイプ出力で起こすツール（Claude Code など）に、starship の precmd / preexec が吐くエスケープがコマンド出力へ混入するのを防ぐため。

```bash
ln -sfn ~/dotfiles/bash/bashrc ~/.bashrc
```

## セットアップ

```bash
git clone git@github.com:autre-temps/dotfiles.git ~/dotfiles

# nvim
ln -s ~/dotfiles/nvim ~/.config/nvim

# starship
ln -sfn ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# claude（詳細は claude/README.md）
ln -sfn ~/dotfiles/claude/settings.json ~/.claude/settings.json
mkdir -p ~/.claude/output-styles ~/.claude/skills/commit
ln -sfn ~/dotfiles/claude/output-styles/vampire-maid.md ~/.claude/output-styles/vampire-maid.md
ln -sfn ~/dotfiles/claude/skills/commit/SKILL.md ~/.claude/skills/commit/SKILL.md

# ccstatusline
mkdir -p ~/.config/ccstatusline
ln -sfn ~/dotfiles/ccstatusline/settings.json ~/.config/ccstatusline/settings.json

# bash
ln -sfn ~/dotfiles/bash/bashrc ~/.bashrc
```
