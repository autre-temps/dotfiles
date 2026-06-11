# claude

[Claude Code](https://claude.com/claude-code) の個人設定のうち、共有・バージョン管理してよい部分だけを切り出したものです。この dotfiles の一部として管理し、`~/.claude` 配下へ **symlink** で展開します。
`~/.claude` を丸ごと追跡するのではなく、再現に必要な「設定・スキル・出力スタイル」のみを収めています。認証情報や履歴などの機密ファイルは意図的に含めていません。

## 構成

`~/.claude` 配下の階層をそのまま写した形で収めています。

```
claude/
├── README.md                    このファイル
├── settings.json                Claude Code の共通設定（permissions / hooks / 表示など）
├── output-styles/
│   └── vampire-maid.md          出力スタイル「Vampire Maid」
└── skills/
    └── commit/
        └── SKILL.md             /commit スキル（安全な Git コミット手順）
```

## 各ファイルの内容

### `settings.json`

Claude Code の共通設定です。主な項目は次のとおりです。

- **`permissions`** — `allow` / `deny` でツール実行の許否を制御します。
  - `deny` で `sudo`、`git reset`、`git rebase`、`wget`、`.env*` や秘密鍵（`id_rsa` / `id_ed25519`）の読み書きを禁止しています。
- **`hooks`** — ツール実行の前後に走るフックです。
  - `PreToolUse`（Bash）: `rm -rf` などの破壊的コマンドをブロックします。
  - `PostToolUse`（Write/Edit）: `.js` / `.ts` 系は `prettier`、`.py` は `uv run ruff format` で自動整形し、Bash コマンドは `~/.claude/command_history.log` に記録します。
- **表示・挙動**
  - `outputStyle`: `Vampire Maid`
  - `language`: `japanese`
  - `theme`: `dark`
  - `effortLevel`: `xhigh`
  - `spinnerVerbs`: スピナー表示を `給仕中` に置き換え
  - `statusLine`: [ccstatusline](https://www.npmjs.com/package/ccstatusline) を利用。`bun add -g ccusage ccstatusline` でグローバル導入し、`~/.bun/bin` の実体を直に呼びます（`npx` での都度取得はしません）。

### `skills/commit/SKILL.md`

`/commit` スキルの定義です。Python プロジェクト（`uv run` + `ruff` + `pytest`）を前提に、状態確認 → 変更の整理 → チェック → メッセージ案作成 → 確認ゲート、という手順で安全にコミットを準備します。明示的な確認なしにはコミットせず、秘密情報を含めない方針を組み込んでいます。

### `output-styles/vampire-maid.md`

出力スタイル「Vampire Maid」の定義です。永い夜を生きる女吸血鬼でありながら、英国の格式ある屋敷に仕えるメイドとして振る舞う人格を与えます。作業の正確さ・簡潔さは保ったまま、語り口だけを慇懃で優雅なものに染めます。

## 適用方法（symlink）

各ファイルを、対応する `~/.claude` 配下へ symlink で結びます。リポジトリ側を編集すれば、そのまま `~/.claude` に反映されます。

```bash
# 設定本体
ln -sfn ~/dotfiles/claude/settings.json ~/.claude/settings.json

# 出力スタイル
mkdir -p ~/.claude/output-styles
ln -sfn ~/dotfiles/claude/output-styles/vampire-maid.md ~/.claude/output-styles/vampire-maid.md

# スキル
mkdir -p ~/.claude/skills/commit
ln -sfn ~/dotfiles/claude/skills/commit/SKILL.md ~/.claude/skills/commit/SKILL.md
```

> [!NOTE]
> `~/.claude` 側に実体ファイルが既にある場合、`ln -sfn` がそれを symlink で置き換えます。必要に応じて先にバックアップを取ってください。

## 含めていないもの

機密情報・端末固有・履歴系のファイルは、ここでは管理しません。

- `settings.local.json`（端末固有の許可設定など）
- `.credentials.json`
- `history.jsonl` / `command_history.log`
- `sessions/` / `projects/` / `session-env/`
- `backups/`、`settings.json.bak`、`settings.json.orig`
