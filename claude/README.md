# claude

[Claude Code](https://claude.com/claude-code) の個人設定のうち、共有・バージョン管理してよい部分だけを切り出したものです。この dotfiles の一部として管理し、`~/.claude` 配下へ **symlink** で展開します。
`~/.claude` を丸ごと追跡するのではなく、再現に必要な「設定・スキル・出力スタイル」のみを収めています。認証情報や履歴などの機密ファイルは意図的に含めていません。

## 構成

`~/.claude` 配下の階層をそのまま写した形で収めています。

```
claude/
├── README.md                    このファイル
├── CLAUDE.md                    全般の行動規範（モデルへの共通指示）
├── settings.json                Claude Code の共通設定（permissions / hooks / 表示など）
├── hooks/
│   └── bash-guard.sh            Bash 実行前の門番（破壊的コマンド・秘密情報の検知）
├── output-styles/
│   └── vampire-maid.md          出力スタイル「Vampire Maid」
└── skills/
    ├── commit/
    │   └── SKILL.md             /commit スキル（安全な Git コミット手順）
    └── japanese-tech-writing/
        └── SKILL.md             日本語技術文書の文章規範
```

## 各ファイルの内容

### `CLAUDE.md`

Claude Code 全体に効かせる行動規範です。`~/.claude/CLAUDE.md` として展開され、すべてのセッションの共通指示になります。`settings.json` の `permissions` / `hooks` が機械的な防壁を担うのに対し、こちらはモデル自身の判断の指針（防壁をすり抜けた場合の二重の歯止め）を受け持ちます。破壊的操作の禁止、権限昇格・秘密情報への不接触、外部影響のある操作の事前確認、ツール実行前の説明義務などを定めています。

### `settings.json`

Claude Code の共通設定です。主な項目は次のとおりです。

- **`permissions`** — `allow` / `deny` / `ask` でツール実行の許否を制御します。`defaultMode` は `auto`（実行前に別モデルの classifier が審査し、逸脱した操作だけを差し止めるモード）で、`disableBypassPermissionsMode` により無審査の `bypassPermissions` は封じています。
  - `deny` で `sudo`・`chmod`・`chown`・`mkfs`・`dd`・`rm -rf`・`crontab`・シェル eval 系（`bash -c` / `python -c` 等）を禁止し、`.env*` や秘密鍵（`id_rsa` / `id_ed25519`）・クラウド認証情報の読み書きも禁止しています。
  - `ask` で `git push`・`git reset --hard`・`git rebase`・`wget`・`curl`・`docker`・`npm publish`・`rm` など、取り消しが難しい操作や外部送信を確認付きにしています。`ask` は `auto` モードでも classifier を迂回して必ず停止するため、ここに置くのは人の目を通したいものだけに絞ります（`cat`・`echo` のような読むだけの操作は置きません）。
- **`sandbox`** — Bash 実行をファイルシステム・ネットワークごと隔離する設定です。現在は `enabled: false` で伏せてあり、防壁は `permissions` と `bash-guard.sh` が担っています。有効にすれば、書き込み先・通信先を OS が強制する層が加わります。Linux でこの隔離を支えるのは `bubblewrap`（`bwrap`、コマンドの隔離）と `socat`（許可ドメインへのネットワーク濾過）で、`install.sh` が apt で導入済みです。`failIfUnavailable` を立ててあるため、有効化後に檻を組めない環境では Bash を止めます。
- **`hooks`** — ツール実行の前後に走るフックです。
  - `PreToolUse`（Bash）: [`hooks/bash-guard.sh`](hooks/bash-guard.sh) を呼び、破壊的コマンドと秘密情報への接触を差し止めます（後述）。
  - `PostToolUse`（Write/Edit）: `.js` / `.ts` 系は `prettier`、`.py` は `uv run ruff format` で自動整形し、Bash コマンドは `~/.claude/command_history.log` に記録します。
  - `Stop`: セッション終了時に Windows 通知音を鳴らし、`command_history.log` が 1MB を超えていれば空にします。
  - `Notification`: 通知イベント時に Windows の nudge 音を鳴らします。
- **表示・挙動**
  - `model`: `opus[1m]`（1M コンテキストの Opus）
  - `outputStyle`: `Vampire Maid`
  - `language`: `japanese`
  - `theme`: `dark`
  - `effortLevel`: `xhigh`
  - `spinnerVerbs`: スピナー表示を `給仕中` に置き換え
  - `statusLine`: [ccstatusline](https://www.npmjs.com/package/ccstatusline) を利用。`install.sh` が `bun install -g ccstatusline` で導入し、`~/.local/bin/ccstatusline` の実体を絶対パスで直に呼びます（`npx` での都度取得はしません）。表示の設定は [`ccstatusline/settings.json`](../ccstatusline/settings.json) にあり、`~/.config/ccstatusline/settings.json` へ symlink されます。
  - `enabledPlugins`: `frontend-design@claude-plugins-official` プラグインを有効化

### `hooks/bash-guard.sh`

`PreToolUse`（Bash）から呼ばれる門番です。**実際に走るコマンドだけ**を見て、破壊的な操作（`rm` の再帰削除・`dd`・`mkfs`・fork bomb）と秘密情報への接触（`.env` / `~/.ssh` / `~/.aws` / `*.pem` / `.npmrc` ほか `CLAUDE.md` に挙げた一式）を差し止めます。

素朴な `grep` で命令文全体を検査すると、コミットメッセージの `.env`、`grep` の検索語 `credentials`、註釈やヒアドキュメント本文に書いた `rm -rf` まで獲物と見誤ります。この門番は次の手順で言及と実行を分けます。

1. ヒアドキュメント本文を落とす。ただし `bash <<EOF` のように解釈器へ流す本文は実際に走るため残す
2. 簡易なシェル字句解析でトークンへ割る。クォート内は 1 トークンにまとめ、行コメントは捨てる。`"..."` の中の `$( )` や `` ` ` `` は別立てで再検査する
3. 破壊的コマンドは**コマンド位置のトークン**だけを見る。`sudo` / `xargs` / `timeout` などの被せ物は剥がし、`find -exec` の後ろも命令として扱う
4. 秘密情報は**パスの形をしたトークン**だけを見る。空白を含む文字列（＝文章や検索語）と、パスでないオプション値は見ない。`.env.example` の類は見本として通す

なお `bash -c` / `sh -c` / `python -c` / `node -e` のように文字列を解釈器へ渡す経路は、この門番ではなく `permissions.deny` が受け持ちます。

### `skills/commit/SKILL.md`

`/commit` スキルの定義です。Python プロジェクト（`uv run` + `ruff` + `pytest`）を前提に、状態確認 → 変更の整理 → チェック → メッセージ案作成 → 確認ゲート、という手順で安全にコミットを準備します。明示的な確認なしにはコミットせず、秘密情報を含めない方針を組み込んでいます。

### `skills/japanese-tech-writing/SKILL.md`

日本語の技術文書・書籍原稿の文章規範です。一文一行や脚注といった整形、パラグラフライティングによる段落構成、論証の厳密さ、読み手の負荷の管理、冗長の排除などを定めます。日本語で章・記事・解説文を書くとき、また推敲するときに働きます。

> [!NOTE]
> このスキルは `install.sh` の symlink 対象に入っていないため、`~/.claude/skills/` へは展開されていません。利用するには `install.sh` へ結び付けを追加してください。

### MCP サーバー

MCP（Model Context Protocol）サーバーは設定ファイルとしては持たず、`install.sh` が `claude mcp add-json --scope user` で登録します（既に登録済みなら飛ばすため冪等）。現在登録するのは `pdf-mcp`（`uvx` 経由で起動。PDF の抽出・検索・構造解析）です。

### `output-styles/vampire-maid.md`

出力スタイル「Vampire Maid」の定義です。永い夜を生きる女吸血鬼でありながら、英国の格式ある屋敷に仕えるメイドとして振る舞う人格を与えます。作業の正確さ・簡潔さは保ったまま、語り口だけを慇懃で優雅なものに染めます。

## 適用方法（symlink）

各ファイルを、対応する `~/.claude` 配下へ symlink で結びます。リポジトリ側を編集すれば、そのまま `~/.claude` に反映されます。この展開はリポジトリ直下の [`install.sh`](../install.sh) が一括して行うため、手作業は不要です。

`install.sh` が結ぶのは次の五つ（`~/.claude` を館ごと結ばず、必要なファイルだけを個別に結ぶ方針です）。

- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `claude/settings.json` → `~/.claude/settings.json`
- `claude/hooks/bash-guard.sh` → `~/.claude/hooks/bash-guard.sh`
- `claude/output-styles/vampire-maid.md` → `~/.claude/output-styles/vampire-maid.md`
- `claude/skills/commit/SKILL.md` → `~/.claude/skills/commit/SKILL.md`

さらに MCP サーバー `pdf-mcp` を `claude mcp add-json --scope user` で登録します（symlink ではなく登録。冪等）。

> [!NOTE]
> `~/.claude` 側に実体ファイルが既にある場合、`install.sh` は上書きせず `.bak.<epoch>` へ退避してから symlink を結びます。退避先は元の場所に残るので、必要なら後から戻せます。

## 含めていないもの

機密情報・端末固有・履歴系のファイルは、ここでは管理しません。

- `settings.local.json`（端末固有の許可設定など）
- `.credentials.json`
- `history.jsonl` / `command_history.log`
- `sessions/` / `projects/` / `session-env/`
- `backups/`、`settings.json.bak`、`settings.json.orig`
