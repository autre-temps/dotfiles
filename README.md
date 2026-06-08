# dotfiles

個人開発環境の設定ファイル群。各ディレクトリを、対応する設定先へ **symlink** で展開して使う。

想定環境: WSL2 (Debian) を主とする Linux。

> **前提**: アイコンを含む UI を正しく表示するため、[Nerd Font](https://www.nerdfonts.com/) を端末に導入し、ターミナルの表示フォントに設定しておくこと。

## 構成

```
dotfiles/
├── nvim/      Neovim 設定（lazy.nvim ベース・Python 開発向け）→ ~/.config/nvim
└── claude/    Claude Code 設定（settings / skills / output-styles）→ ~/.claude 配下
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

## claude

[Claude Code](https://claude.com/claude-code) の共有可能な設定（`settings.json` / `/commit` スキル / 出力スタイル）。`~/.claude` 配下には認証情報や履歴が同居するため館ごとは symlink せず、必要なファイルだけを個別に結ぶ。

詳細とファイル単位の展開手順は [`claude/README.md`](claude/README.md) を参照。

```bash
ln -sfn ~/dotfiles/claude/settings.json ~/.claude/settings.json
mkdir -p ~/.claude/output-styles ~/.claude/skills/commit
ln -sfn ~/dotfiles/claude/output-styles/vampire-maid.md ~/.claude/output-styles/vampire-maid.md
ln -sfn ~/dotfiles/claude/skills/commit/SKILL.md ~/.claude/skills/commit/SKILL.md
```

## セットアップ

```bash
git clone git@github.com:autre-temps/dotfiles.git ~/dotfiles

# nvim
ln -s ~/dotfiles/nvim ~/.config/nvim

# claude（詳細は claude/README.md）
ln -sfn ~/dotfiles/claude/settings.json ~/.claude/settings.json
mkdir -p ~/.claude/output-styles ~/.claude/skills/commit
ln -sfn ~/dotfiles/claude/output-styles/vampire-maid.md ~/.claude/output-styles/vampire-maid.md
ln -sfn ~/dotfiles/claude/skills/commit/SKILL.md ~/.claude/skills/commit/SKILL.md
```
