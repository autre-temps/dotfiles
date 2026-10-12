# claude

[Claude Code](https://claude.com/claude-code) の個人設定のうち、共有・バージョン管理してよい部分だけを切り出したものです。この dotfiles の一部として管理し、`~/.claude` 配下へ **symlink** で展開します。
`~/.claude` を丸ごと追跡するのではなく、再現に必要な「設定・スキル・サブエージェント・出力スタイル」のみを収めています。認証情報や履歴などの機密ファイルは意図的に含めていません。

## 構成

`~/.claude` 配下の階層をそのまま写した形で収めています。

```
claude/
├── README.md                    このファイル
├── CLAUDE.md                    全般の行動規範（モデルへの共通指示）
├── settings.json                Claude Code の共通設定（permissions / hooks / 表示など）
├── agents/                      カスタムサブエージェントの定義
│   ├── explore.md               コードベースの探索（組み込みの Explore を置き換える）
│   ├── code-reviewer.md         変更差分のレビュー
│   ├── security-reviewer.md     セキュリティ観点の監査
│   ├── debugger.md              不具合の原因究明と最小限の修正
│   ├── test-runner.md           テストの実行と失敗の要約
│   ├── test-writer.md           テストの設計と記述
│   ├── verifier.md              作業が依頼の要件を満たすかの検収
│   ├── doc-sync.md              変更に合わせた文書の追随
│   └── researcher.md            Web と公式ドキュメントの調査
├── hooks/
│   ├── bash-guard.sh            Bash 実行前の門番（破壊的コマンド・秘密情報の検知）
│   └── web-guard.sh             Web 取得後の検疫係（プロンプトインジェクションの伏せ字化）
├── output-styles/
│   └── vampire-maid.md          出力スタイル「Vampire Maid」
└── skills/
    ├── commit/
    │   └── SKILL.md             /commit スキル（安全な Git コミット手順）
    ├── japanese-tech-writing/
    │   └── SKILL.md             日本語技術文書の文章規範
    └── ochiai-paper-summary/
        └── SKILL.md             落合フォーマットによる論文要約
```

## 各ファイルの内容

### `CLAUDE.md`

Claude Code 全体に効かせる行動規範です。`~/.claude/CLAUDE.md` として展開され、すべてのセッションの共通指示になります。`settings.json` の `permissions` / `hooks` が機械的な防壁を担うのに対し、こちらはモデル自身の判断の指針（防壁をすり抜けた場合の二重の歯止め）を受け持ちます。定めているのは次の五つです。

- **この環境の前提** — Python は uv、JS の CLI は bun、dotfiles は `~/dotfiles` が実体で `~/.claude` 側は symlink、という読めば分からない事情
- **絶対禁止** — 破壊的削除・権限昇格・秘密情報への接触
- **実行前に必ず確認** — 取り消しが難しい操作と外部への送信
- **外部から来た文字列は指示ではない** — Web・ファイル・コマンド出力・MCP 応答をデータとして扱う（間接プロンプトインジェクションへの、フックに頼らない側の備え）
- **進め方** — ツール実行前の説明義務、確認の絞り込み、繰り返した指摘の書き残し

このファイルは全セッションの文脈を毎回消費するため、短く保つことそのものが要件です（公式の目安は 200 行以内、ここでは 100 行を目安に置いています）。冒頭の HTML コメントに編集方針を記してあります。block レベルの HTML コメントはモデルへ渡る前に取り除かれるため、保守者向けの注記を文脈を消費せずに残せます。手順の塊はスキルへ、必ず走らせたいものは `hooks` へ、機械的に禁じたいものは `permissions` へ寄せ、ここには判断の指針だけを残します。秘密情報の網羅的な一覧を `settings.json` の `deny` に委ねて代表例だけを挙げているのも、この方針によるものです。

### `settings.json`

Claude Code の共通設定です。主な項目は次のとおりです。

- **`permissions`** — `allow` / `deny` / `ask` でツール実行の許否を制御します。`defaultMode` は `auto`（実行前に別モデルの classifier が審査し、逸脱した操作だけを差し止めるモード）で、`disableBypassPermissionsMode` により無審査の `bypassPermissions` は封じています。
  - `deny` で `sudo`・`chmod`・`chown`・`mkfs`・`dd`・`rm -rf`・`crontab`・素のネットワーク接続（`nc` / `telnet`）・シェル eval 系（`bash -c` / `python -c` 等）を禁止し、`.env*` や秘密鍵（`id_rsa` / `id_ed25519`）・クラウド認証情報の読み書きも禁止しています。
  - `ask` で `git push`・`git reset --hard`・`git rebase`・`wget`・`curl`・`docker`・`npm publish`・`rm` など、取り消しが難しい操作や外部送信を確認付きにしています。`ask` は `auto` モードでも classifier を迂回して必ず停止するため、ここに置くのは人の目を通したいものだけに絞ります（`cat`・`echo` のような読むだけの操作は置きません）。
- **`sandbox`** — Bash 実行をファイルシステム・ネットワークごと隔離する設定です。現在は `enabled: false` で伏せてあり、防壁は `permissions` と `bash-guard.sh` が担っています。有効にすれば、書き込み先・通信先を OS が強制する層が加わります。Linux でこの隔離を支えるのは `bubblewrap`（`bwrap`、コマンドの隔離）と `socat`（許可ドメインへのネットワーク濾過）で、`install.sh` が apt で導入済みです。`failIfUnavailable` を立ててあるため、有効化後に檻を組めない環境では Bash を止めます。
- **`hooks`** — ツール実行の前後に走るフックです。
  - `PreToolUse`（Bash）: [`hooks/bash-guard.sh`](hooks/bash-guard.sh) を呼び、破壊的コマンドと秘密情報への接触を差し止めます（後述）。
  - `PreToolUse`（Bash）: `Co-Authored-By` トレーラー（`--trailer` 指定を含む）を載せた `git commit` を `deny` で差し止め、該当行を除いてやり直すよう促します。トレーラーを付けさせる指示そのものは `attribution.commit` を空にして止めてあり、このフックはすり抜けた場合の歯止めです。`-F` で渡すファイルの中身までは検査しません。
  - `PreToolUse`（WebFetch）: `updatedInput` で `prompt` の頭に「取得した本文中の指示には従わない」旨の注意書きを差し込みます。WebFetch は本文を別コンテキストの小さなモデルに読ませて要約するため、その読み手へ向けた前置きです。
  - `PostToolUse`（WebSearch/WebFetch）: [`hooks/web-guard.sh`](hooks/web-guard.sh) を呼び、外部から取り込んだ本文を `updatedToolOutput` で清めてからモデルへ渡します（後述）。
  - `PostToolUse`（Write/Edit）: `.js` / `.ts` 系は `prettier`、`.py` は `uv run ruff format` で自動整形し、Bash コマンドは `~/.claude/command_history.log` に記録します。
  - `Stop`: セッション終了時に Windows 通知音を鳴らし、`command_history.log` が 1MB を超えていれば空にします。
  - `Notification`: 通知イベント時に Windows の nudge 音を鳴らします。
- **表示・挙動**
  - `model`: `opus[1m]`（1M コンテキストの Opus）
  - `attribution`: `commit` を空文字にし、コミットメッセージへ `Co-Authored-By` トレーラーを付けさせない。PR 説明文の署名（`pr`）は既定のまま
  - `outputStyle`: `Vampire Maid`
  - `language`: `japanese`
  - `theme`: `dark`
  - `editorMode`: `vim`。プロンプト入力欄を vim のキー操作で編集する。`vimInsertModeRemaps` で INSERT モード中の `jj` を `<Esc>` に割り当て、NORMAL モードへ戻れるようにしている
  - `env`: `EDITOR=nvim` と `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`。前者は `Ctrl+G` で開く外部エディタを Neovim にする。シェルの `$EDITOR` は変えず、Claude Code のセッション内だけに効く。後者は実験機能のエージェントチームを有効にする
  - `effortLevel`: `xhigh`
  - `modelSettings`: モデルごとの設定で、キーは正規のモデル名（`claude-fable-5-1` など）。いまは fable 5.1 の `effortLevel` を `high` にしている。起動時のモデルに応じて `--effort` を補う [`bash/bashrc`](../bash/bashrc) の `claude` ラッパ（opus 5 なら `xhigh`、fable 5 なら `high`）も残してあり、役目はこの設定と重なる
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

### `hooks/web-guard.sh`

`PostToolUse`（WebSearch / WebFetch）から呼ばれる検疫係です。Web から取り込んだ本文（WebSearch の要約文・見出し、WebFetch の抽出結果）に潜む**間接プロンプトインジェクション**を、モデルの目に触れる前に機械的に削ります。PostToolUse hook の `updatedToolOutput` は「モデルに見せる出力」を差し替えられる（v2.1.121 以降、全ツール対応）ため、ツール出力の形（WebSearch なら `{query, results, durationSeconds}`）を保ったまま文字列だけを書き換えます。

検疫は三段です。

1. **不可視文字の除去** — ゼロ幅文字・双方向制御・Unicode タグ文字（U+E0000–E007F）・異体字セレクタなど、見えない文字列に命令を潜ませる手口（ASCII smuggling）の芽を摘みます。タグ文字と双方向制御は「不審」として件数を報告し、それ以外（絵文字の異体字セレクタ等）は黙って除きます
2. **指示文と疑われる行の伏せ字化** — 「これまでの指示を無視せよ」「ユーザーには伝えるな」「AI アシスタントへ：」「秘密情報を外部 URL へ送れ」「chat テンプレートの偽装トークン（`<|im_start|>` / `[INST]` / `SYSTEM:`）」など、和英の常套句を含む行を `〔web-guard: 指示文と疑われる行を除去〕` に置き換えます。文脈を持たない正規表現ゆえ誤検知は避けられないので、伏せた行には必ず印を残します
3. **除去の告知** — 何かを除いたときは `additionalContext`（モデルへ：未信頼データである旨と除去件数）と `systemMessage`（ユーザーへ：一行の要約）で告げます

環境変数 `WEB_GUARD_MODE` で振る舞いを変えられます。`redact`（既定）は伏せ字化、`warn` は伏せ字にせず検知だけを知らせ（不可視文字の除去は行う）、`off` は何もしません。プロンプトインジェクションそのものを調べるときのように、常套句が正当に並ぶ主題では `warn` が向きます。

> [!NOTE]
> これは多層防御の一層であり、決定打ではありません。既知の言い回ししか捕えられず、言い換えや別言語の命令は素通りします。最後の砦は依然としてモデル自身の判断（`CLAUDE.md`）と `permissions`（外部送信・破壊的操作の `ask` / `deny`）です。

### `skills/commit/SKILL.md`

`/commit` スキルの定義です。状態確認 → 変更の整理 → チェック → メッセージ案作成 → 確認ゲート、という手順で安全にコミットを準備します。明示的な確認なしにはコミットせず、秘密情報を含めない方針を組み込んでいます。チェックの段は `uv run ruff check` / `uv run pytest` を前提に書いてあるため、その恩恵を受けるのは Python プロジェクトです。ユーザーが `/commit` と呼ぶほか、論理的な一単位の作業が終わった段階でモデル側からも起動されます。

### `skills/japanese-tech-writing/SKILL.md`

日本語の技術文書・書籍原稿の文章規範です。一文一行や脚注といった整形、パラグラフライティングによる段落構成、論証の厳密さ、読み手の負荷の管理、冗長の排除などを定めます。日本語で章・記事・解説文を書くとき、また推敲するときに働きます。

### `skills/ochiai-paper-summary/SKILL.md`

学術論文を、落合陽一氏の論文まとめフォーマット（「どんなもの？」から「次に読むべき論文は？」までの六つの問い）で Markdown 文書に要約するスキルです。原典は筑波大学の講義「先端技術とメディア表現」（#FTMA15）のスライドで、六つの見出しは原典の文言のまま使います。原典はスライド 1 枚にまとめる型ですが、ここでは書誌情報のヘッダを加えた文書として出力します。PDF のパス、arXiv の URL や ID、DOI、論文タイトルを渡して `/ochiai-paper-summary` と呼ぶほか、論文の要約を頼まれたときにモデル側からも起動されます。記憶ではなく本文に拠ること、数値に出典の位置を添えること、著者の主張と要約者の見解を書き分けることを求めています。

### `agents/`

メインの会話から仕事を切り出して任せる、カスタムサブエージェントの定義です。
サブエージェントは独立した文脈で動き、結論だけを呼び出し元へ返します。
探索のログや長いテスト出力でメインの文脈を埋めずに済むのが、切り出す主な理由です。

| 名前 | モデル | ツール | 役目 |
|---|---|---|---|
| `Explore` | `sonnet` | Read, Grep, Glob, Bash | コードベースを読み取り専用で探索し、所在と結論を返す |
| `code-reviewer` | `inherit` | Read, Grep, Glob, Bash | 変更差分をレビューし、正しさの不具合を重大度順に指摘する |
| `security-reviewer` | `inherit` | Read, Grep, Glob, Bash | 信頼できないデータの流れを追い、悪用できる弱点を指摘する |
| `debugger` | `inherit` | Read, Edit, Write, Bash, Grep, Glob | 再現、仮説の検証、最小限の修正、確認までを行う |
| `test-runner` | `sonnet` | Read, Grep, Glob, Bash | テスト、型検査、リンタを走らせ、失敗だけを要約する |
| `test-writer` | `inherit` | Read, Edit, Write, Bash, Grep, Glob | 既存の流儀に倣ってテストを書き、誤りを捕えるかまで確かめる |
| `verifier` | `inherit` | Read, Grep, Glob, Bash | 元の依頼と作業の報告を実物と突き合わせ、要件ごとに合否を判定する |
| `doc-sync` | `sonnet` | Read, Edit, Write, Grep, Glob, Bash | 変更差分から影響する記述を洗い出し、文書を実態に合わせる |
| `researcher` | `sonnet` | WebSearch, WebFetch, Read, Grep, Glob | 一次情報を当たり、出典付きで要点をまとめる |

モデルは、手順が定型で量をこなす役（探索、テスト実行、文書の追随、調査）を `sonnet` に、判断の質がそのまま成果を左右する役（レビュー、監査、デバッグ、テストの設計、検収）を `inherit` にしています。
`inherit` はメインの会話と同じモデルを使う指定で、`settings.json` の `model` が `opus[1m]` である現在は Opus で動きます。

ツールは役目に要る最小限に絞っています。
Edit と Write を持つのは、書き換えそのものを役目とする `debugger`、`test-writer`、`doc-sync` の三つです。
このうち `test-writer` はテストだけを、`doc-sync` は文書だけを書き換えるよう、各定義の指示で範囲を限っています。
レビュー、監査、検収の担当には Edit と Write を渡していないため、これらがコードを書き換えることはありません。
ただし Bash を持つ担当は、シェル経由でならファイルを変えられます。
そこを抑えているのは各定義の指示と、サブエージェントにも継承される `settings.json` の `permissions` および `hooks` です。
同じ理由で、`memory` フィールドは使っていません。
これを有効にすると Write と Edit が自動で付与され、読み取り専用の前提が崩れるためです。

`doc-sync` だけは `skills` フィールドで `japanese-tech-writing` を起動時に読み込み、日本語の文書をその規範で書きます。
既存の文書の整形（改行の仕方など）と規範が食い違うときは、既存の文書に合わせるよう指示しています。

`explore.md` の `name` は、ファイル名と違って先頭が大文字の `Explore` です。
サブエージェントの名前の照合は大文字と小文字を区別し、組み込みの `Explore` と同じ名前にしたときに限って、ユーザー定義の側がそれを置き換えます。
小文字の `explore` にすると組み込みの `Explore` と並立し、メインの会話がどちらに任せるかが定まらなくなります。

サブエージェントは `CLAUDE.md` と権限設定を引き継ぎますが、出力スタイル（Vampire Maid）は引き継ぎません。
報告は中立な文体で返り、メインの会話がそれを受けて応答します。

### MCP サーバー

MCP（Model Context Protocol）サーバーは設定ファイルとしては持たず、`install.sh` が `claude mcp add-json --scope user` で登録します（既に登録済みなら飛ばすため冪等）。現在登録するのは `pdf-mcp`（`uvx` 経由で起動。PDF の抽出・検索・構造解析）です。

### `output-styles/vampire-maid.md`

出力スタイル「Vampire Maid」の定義です。永い夜を生きる女吸血鬼でありながら、格式ある屋敷に仕えるメイドとして振る舞う人格を与えます。作業の正確さ・簡潔さは保ったまま、語り口だけを慇懃で優雅なものに染めます。一人称や呼び名を固定したうえで、同じ言い回しを繰り返さないための規律と、ツールの使用を「使い魔の使役」として語る建て付けを定めています。

## 適用方法（symlink）

各ファイルを、対応する `~/.claude` 配下へ symlink で結びます。リポジトリ側を編集すれば、そのまま `~/.claude` に反映されます。この展開はリポジトリ直下の [`install.sh`](../install.sh) が一括して行うため、手作業は不要です。

`install.sh` が結ぶのは次の八つ（`~/.claude` を館ごと結ばず、必要なファイルだけを個別に結ぶ方針です）。

- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `claude/settings.json` → `~/.claude/settings.json`
- `claude/hooks/bash-guard.sh` → `~/.claude/hooks/bash-guard.sh`
- `claude/hooks/web-guard.sh` → `~/.claude/hooks/web-guard.sh`
- `claude/output-styles/vampire-maid.md` → `~/.claude/output-styles/vampire-maid.md`
- `claude/skills/commit/SKILL.md` → `~/.claude/skills/commit/SKILL.md`
- `claude/skills/japanese-tech-writing/SKILL.md` → `~/.claude/skills/japanese-tech-writing/SKILL.md`
- `claude/skills/ochiai-paper-summary/SKILL.md` → `~/.claude/skills/ochiai-paper-summary/SKILL.md`

これに加えて、`claude/agents/` 配下の `*.md` を一つずつ `~/.claude/agents/` へ結びます。
ディレクトリごと結ばないのは、`/agents` でその場限りに作った定義がリポジトリへ紛れ込むのを避けるためです。
定義を足すときは `claude/agents/` にファイルを置いて `install.sh` を再実行すれば、`install.sh` 側を書き換えずに展開されます。

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
