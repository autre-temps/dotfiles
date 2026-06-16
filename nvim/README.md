# nvim

導入しているプラグインの使い方の覚書。設定の全体構成・展開手順は[母屋の README](../README.md#nvim) を参照。

プラグインの spec は `lua/plugins/` 配下に一つずつ置いてある。

## vim-commentary（コメントアウト）

[tpope/vim-commentary](https://github.com/tpope/vim-commentary) によるコメントアウト操作。
spec は [`lua/plugins/commentary.lua`](lua/plugins/commentary.lua)。

`gc` を起点とした最小限のキー操作で、行・モーション範囲・選択範囲のコメントを切り替える。
コメント記法はファイルタイプごとの `'commentstring'` を参照するため、言語を問わず同じ操作で扱える。

### キーマップ

| 操作 | 説明 |
| --- | --- |
| `gcc` | カレント行をコメント／アンコメント切り替え。`3gcc` のように前置カウントで複数行 |
| `gc{motion}` | モーションが動く範囲を切り替え（例 `gcap` で段落、`gcG` でカーソルから末尾まで） |
| `gcj` | カレント行と下 1 行（計 2 行）を切り替え。`gck` なら上 1 行 |
| `gc`（ビジュアルモード） | 選択した行を切り替え |
| `gcu` | カレント行と隣接するコメント行をまとめてアンコメント |
| `gc`（オペレータ待ち） | コメントそのものを対象に取る（例 `dgc` でコメントを削除） |

> `gc` は「コメントが付いていれば外す／無ければ付ける」のトグル。同じ操作で双方向に働く。

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:[range]Commentary` | 範囲を指定して切り替え（例 `:7,17Commentary`） |
| `:g/{pattern}/Commentary` | パターンに一致する行だけを切り替え（例 `:g/TODO/Commentary`） |

### コメント記法（commentstring）

どの記法でコメント化するかは、各ファイルタイプの `'commentstring'` オプションに従う。
多くの言語は標準の ftplugin や treesitter が適切に設定するため、そのまま動く。

意図した記法にならない場合は、`'commentstring'` を上書きする。`%s` がコメント対象の差し込み位置。

```lua
-- 例: 特定ファイルタイプの commentstring を上書きする
vim.api.nvim_create_autocmd("FileType", {
    pattern = "someft",
    callback = function()
        vim.bo.commentstring = "# %s"
    end,
})
```

### 使用例

```text
gcc        -- この行をトグル
5gcc       -- この行から 5 行をトグル
gcap       -- カーソル位置の段落をトグル
gcip       -- 空行で区切られた塊（インナー段落）をトグル
gcG        -- カーソル行から末尾までをトグル
{Visual}gc -- 選択範囲をトグル
gcu        -- 隣接するコメント行をまとめて外す
```

## lualine（ステータスライン）

[nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) によるステータスライン。
spec は [`lua/plugins/lualine.lua`](lua/plugins/lualine.lua)。配色（`options.theme`）は `"auto"` とし、現在の colorscheme から自動で取得する（colorscheme を変えれば追従する）。

`base.lua` の `laststatus = 3` に合わせて `globalstatus = true` とし、画面下部に一本だけ表示する。区切りは powerline 形状（鋭角のセパレータ）、アイコンは Nerd Font。

### 表示項目

| 区画 | 内容 |
| --- | --- |
| 左（a / b） | モード ／ git ブランチ・差分 |
| 中央（c） | ファイル名（相対パス・変更/読取専用マーク）、noice の状態（録音中マクロ・検索件数） |
| 右（x / y / z） | 起動中の LSP 名 ／ diagnostics ／ encoding ／ filetype ／ 進捗 ／ 位置 ／ 時刻 |

### カスタマイズ

表示項目は spec の `sections` で増減する。lualine は区画を `lualine_a`〜`lualine_z` の名で持ち、各区画にコンポーネント（`"branch"`・`"diagnostics"` などの組み込みや、文字列を返す関数）を並べる。

- 配色を変える: `options.theme`（`"auto"` は colorscheme から自動取得。`"nord"` などの固定テーマ名も指定可）
- 区切り形状を変える: `options.section_separators` / `options.component_separators`
- 一本表示をやめる: `options.globalstatus = false`（併せて `base.lua` の `laststatus` を `2` に）

> 依存の [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) はファイルタイプアイコン用。Nerd Font が端末フォントに設定されていないとアイコンは豆腐になる。

### 導入

`lua/plugins/` に spec を置けば、次回 nvim 起動時に lazy.nvim が自動でインストールする。確実に取り込む・バージョンを固定するには `:Lazy sync`。

## fzf-lua（ファジーファインダー）

[ibhagwan/fzf-lua](https://github.com/ibhagwan/fzf-lua) による全文検索・ファイル/バッファ絞り込み・LSP ナビゲーション。
spec は [`lua/plugins/fzf-lua.lua`](lua/plugins/fzf-lua.lua)。

`~/.fzf` の fzf バイナリを直接利用する。プレビューは fzf-lua 内蔵のレンダラーを使うため bat は不要。グレップには **ripgrep** (`rg`) が入っていると速度と精度が格段に上がる（未導入の場合は `grep` で動作するが低速）。

```sh
# ripgrep の導入（強く推奨）
sudo apt install ripgrep
```

### キーマップ

すべてノーマルモード。`<Space>fg` のみビジュアルモードでも使用可。

#### ファイル・バッファ

| キー | 説明 |
| --- | --- |
| `<Space>ff` | カレントディレクトリ以下のファイルを検索 |
| `<Space>fr` | 最近開いたファイル（oldfiles）を検索 |
| `<Space>fb` | 開いているバッファを検索 |

#### グレップ

| キー | 説明 |
| --- | --- |
| `<Space>fg` | ライブグレップ（入力に連動して検索。ビジュアル選択中に押すと選択テキストで検索） |
| `<Space>fw` | カーソル下の単語でグレップ |
| `<Space>fc` | 現在のバッファ内の行を絞り込み |

#### LSP

> LSP 未接続バッファでは何も表示されない。Python ファイルを開いた状態で使うこと。

| キー | 説明 |
| --- | --- |
| `<Space>ls` | バッファ内のシンボル一覧（関数・クラス等） |
| `<Space>lS` | ワークスペース全体のシンボル一覧 |
| `<Space>ld` | バッファの diagnostics 一覧 |
| `<Space>lD` | ワークスペース全体の diagnostics 一覧 |

> 既存の `gd`（定義ジャンプ）・`gr`（参照）・`gi`（実装）は `lsp.lua` の `on_attach` が保持する。

#### Git

| キー | 説明 |
| --- | --- |
| `<Space>gc` | git コミット履歴を表示（Enter でそのコミットの差分をプレビュー） |
| `<Space>gs` | git status（Enter で diff をプレビュー） |

#### その他

| キー | 説明 |
| --- | --- |
| `<Space>fh` | ヘルプタグを検索 |
| `<Space>fk` | 定義済みキーマップを一覧・検索 |
| `<Space>f:` | コマンド履歴を検索 |

### ウィンドウ内のキー操作

fzf-lua のウィンドウが開いているとき、以下のキーが使える。

| キー | 説明 |
| --- | --- |
| `Enter` | 選択して開く |
| `Ctrl-v` | 垂直分割で開く |
| `Ctrl-s` | 水平分割で開く |
| `Ctrl-t` | タブで開く |
| `Ctrl-c` / `Esc` | 閉じる |
| `Ctrl-f` / `Ctrl-b` | プレビューを上下スクロール |

### `:FzfLua` コマンド

すべての機能は `:FzfLua <picker>` でも呼び出せる。

```text
:FzfLua files
:FzfLua live_grep
:FzfLua buffers
:FzfLua git_commits
```

ピッカー名一覧は `:FzfLua` のみで補完される。

## claudecode.nvim（Claude Code 連携）

[coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) による Claude Code の nvim 統合。
spec は [`lua/plugins/claudecode.lua`](lua/plugins/claudecode.lua)。

Claude Code のターミナルを nvim 内に右ペインとして開き、バッファの追加・選択範囲の送信・diff の承認／拒否をキーマップから行える。

### キーマップ

すべてノーマルモード（`<leader>as` のみビジュアルモード兼用）。

| キー | 説明 |
| --- | --- |
| `<leader>ac` | Claude Code ターミナルをトグル |
| `<leader>af` | Claude Code ターミナルにフォーカス |
| `<leader>ar` | `--resume` で前回のセッションを再開 |
| `<leader>ab` | 現在のバッファをコンテキストに追加 |
| `<leader>as`（ビジュアル） | 選択範囲を Claude Code に送信 |
| `<leader>as`（oil / netrw / picker 上） | ツリー上のファイルをコンテキストに追加 |
| `<leader>aa` | diff を承認 |
| `<leader>ad` | diff を拒否 |

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:ClaudeCode` | ターミナルをトグル |
| `:ClaudeCodeFocus` | ターミナルにフォーカス |
| `:ClaudeCodeAdd {file}` | ファイルをコンテキストに追加 |
| `:ClaudeCodeSend` | 選択テキストを送信 |
| `:ClaudeCodeDiffAccept` | diff を承認 |
| `:ClaudeCodeDiffDeny` | diff を拒否 |

## blink.cmp（補完）

[saghen/blink.cmp](https://github.com/Saghen/blink.cmp) による補完エンジン。
spec は [`lua/plugins/completion.lua`](lua/plugins/completion.lua)。

Rust 製のファジーマッチャーを内蔵しており、バイナリ同梱のリリースタグにピン留めしているため Rust ツールチェーンは不要。LSP・パス・スニペット・バッファを補完ソースとして使用する。シグネチャヒントとドキュメント自動表示（200ms 遅延）も有効。

スニペットは [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) をソースとする。

### キーマップ（`default` プリセット）

| キー | 説明 |
| --- | --- |
| `<C-n>` / `<C-p>` | 候補を下 / 上に移動 |
| `<C-y>` | 選択中の候補を確定 |
| `<C-space>` | 補完メニューをトグル |
| `<C-e>` | 補完をキャンセル |

## conform.nvim（フォーマッター）

[stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) による保存時フォーマット。
spec は [`lua/plugins/conform.lua`](lua/plugins/conform.lua)。

`BufWritePre` で自動実行し、Python ファイルに対して Mason が導入した ruff で `ruff_organize_imports → ruff_format` の順に整形する。LSP フォーマットは使わず ruff バイナリを直接呼び出す。タイムアウトは 1000ms。

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:ConformInfo` | 現在のバッファに適用されるフォーマッターとその状態を表示 |

## toggleterm.nvim（ターミナル）

[akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) によるターミナル切り替え。
spec は [`lua/plugins/toggleterm.lua`](lua/plugins/toggleterm.lua)。

`<C-\>` でフローティングウィンドウのターミナルをトグルする。ノーマルモード・ターミナルモードどちらからでも同じキーで開閉できる。

### キーマップ

| キー | 説明 |
| --- | --- |
| `<C-\>` | ターミナルをトグル（ノーマル・ターミナルモード共通） |

## render-markdown.nvim（Markdown レンダリング）

[MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) によるバッファ内 Markdown レンダリング。
spec は [`lua/plugins/render-markdown.lua`](lua/plugins/render-markdown.lua)。

見出し・箇条書き・コードブロック・テーブル・引用をバッファ内で直接リッチ表示する。`markdown` filetype のバッファで遅延ロード。表示のオン／オフは `:RenderMarkdown toggle` で切り替えられる。

依存として `nvim-web-devicons` が必要。`markdown` / `markdown_inline` パーサーは Neovim 同梱のため別途インストール不要。

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:RenderMarkdown toggle` | レンダリングのオン／オフを切り替え |
| `:RenderMarkdown enable` | レンダリングを有効化 |
| `:RenderMarkdown disable` | レンダリングを無効化 |

## tree-sitter-manager.nvim（Tree-sitter パーサー管理）

[romus204/tree-sitter-manager.nvim](https://github.com/romus204/tree-sitter-manager.nvim) による Tree-sitter パーサーの管理とハイライト。
spec は [`lua/plugins/tree-sitter-manager.lua`](lua/plugins/tree-sitter-manager.lua)。

アーカイブされた `nvim-treesitter` の後継として導入。`auto_install = true` で開いたファイルのパーサーを自動取得する。Neovim 同梱パーサー（`c`・`lua`・`markdown` 等）はスキップ。パーサーのビルドには tree-sitter CLI（`bun install -g tree-sitter-cli`）と C コンパイラが必要。

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:TSManager` | パーサー管理 UI を開く |
| `:TSInstall {lang}` | 指定言語のパーサーをインストール |
| `:TSUninstall {lang}` | 指定言語のパーサーをアンインストール |

## noice.nvim（UI 改善）

[folke/noice.nvim](https://github.com/folke/noice.nvim) によるコマンドラインと通知の UI 刷新。
spec は [`lua/plugins/noice.lua`](lua/plugins/noice.lua)。

Ex コマンドライン・検索プロンプトを画面下部の固定行でなく画面中央のポップアップで表示する（`command_palette` プリセット）。通知は [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify) でフローティングウィンドウ表示になる。[MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim) が UI コンポーネントの基盤として必須。

## oil.nvim（ファイラー）

[stevearc/oil.nvim](https://github.com/stevearc/oil.nvim) によるバッファ編集型ファイラー。
spec は [`lua/plugins/oil.lua`](lua/plugins/oil.lua)。

ディレクトリの内容を通常バッファとして開き、行の追加・削除・変名・移動を行ってから `:w` で確定するという操作体系。`nvim .` でディレクトリを開いたときに netrw の代わりに起動するよう `lazy = false` で即時ロード。

### キーマップ

| キー | 説明 |
| --- | --- |
| `-` | 親ディレクトリを oil で開く |
| `-`（oil バッファ内） | さらに上の親へ移動 |
| `<Enter>` | ファイルを開く / ディレクトリへ移動 |

### ファイル操作の流れ

```text
-          -- oil バッファを開く
（行を追加） -- 新規ファイル作成
（行を削除） -- ファイル削除
（行をコピー＆改名） -- ファイル名変更・移動
:w         -- 変更を確定（削除は確認ダイアログあり）
```

## winresizer（ウィンドウリサイズ）

[simeji/winresizer](https://github.com/simeji/winresizer) によるインタラクティブなウィンドウサイズ変更。
spec は [`lua/plugins/winresizer.lua`](lua/plugins/winresizer.lua)。

`<C-e>` でリサイズモードに入り、hjkl でウィンドウの境界を動かす。`Enter` で確定、`q` でキャンセル。縦分割・横分割どちらの境界にも対応。

### 操作

| キー | 説明 |
| --- | --- |
| `<C-e>` | リサイズモード開始 |
| `h` / `l` | 左右の境界を移動 |
| `j` / `k` | 上下の境界を移動 |
| `Enter` | リサイズを確定 |
| `q` | リサイズをキャンセル |

## dracula.nvim（カラースキーム）

[Mofiqul/dracula.nvim](https://github.com/Mofiqul/dracula.nvim) による Dracula カラースキーム。
spec は [`lua/plugins/dracula.lua`](lua/plugins/dracula.lua)。

`priority = 1000` で最優先・即時ロードし、他プラグインの colorscheme 参照（lualine の `theme = "auto"` 等）より先に適用する。有効化は `lua/config/base.lua` の `colorscheme dracula`。

## dropbar.nvim（winbar パンくずリスト）

[Bekaboo/dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim) による IDE 風のパンくずリスト表示。
spec は [`lua/plugins/dropbar.lua`](lua/plugins/dropbar.lua)。

ウィンドウ上部の winbar に現在のカーソル位置（ファイルパス → シンボル階層）を表示する。ソースは LSP を優先し、未接続の場合は Treesitter にフォールバック。Markdown ファイルは専用ソースで見出し階層を表示する。

依存として `nvim-web-devicons` が必要。

### キーマップ

| キー | 説明 |
| --- | --- |
| `<leader>;` | 現在位置のシンボルを fzf 風ピッカーで絞り込み（クリックと同等の操作をキーボードで行える） |

## bufferline.nvim（バッファライン）

[akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) による、開いているバッファのタブ風表示。
spec は [`lua/plugins/bufferline.lua`](lua/plugins/bufferline.lua)。

画面上部の tabline に、開いている各バッファをタブ風に並べる。既定の **buffers モード**で動作し、ファイル名・ファイルタイプアイコン・変更マーク・LSP の diagnostics 件数を各タブに表示する。配色は現在の colorscheme（Dracula）に追従し、区切りは lualine の powerline 形状に合わせた `slant`（斜めの区切り）。

> このプラグインが扱うのは Vim の**タブページ**ではなく**バッファ**。`gh`/`gl`・`te`/`gn`（`keymaps.lua`）のタブページ操作とは独立しており、併用できる。

依存として [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) が必要。Nerd Font が端末フォントに設定されていないとアイコンは豆腐になる。

### キーマップ

すべてノーマルモード。

| キー | 説明 |
| --- | --- |
| `[b` | 前のバッファへ移動 |
| `]b` | 次のバッファへ移動 |
| `[B` | カレントバッファをタブ列の左へ移動 |
| `]B` | カレントバッファをタブ列の右へ移動 |
| `<leader>bp` | カレントバッファのピン留めをトグル |
| `<leader>bo` | カレント以外のバッファを閉じる |

> バッファの絞り込み・選択は fzf-lua の `<Space>fb`（開いているバッファを検索）も利用できる。

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:BufferLineCyclePrev` / `:BufferLineCycleNext` | 前 / 次のバッファへ移動 |
| `:BufferLineMovePrev` / `:BufferLineMoveNext` | バッファをタブ列の左 / 右へ移動 |
| `:BufferLineTogglePin` | カレントバッファのピン留めをトグル |
| `:BufferLineCloseOthers` | カレント以外のバッファを閉じる |
| `:BufferLinePick` | 文字キーでバッファをジャンプ選択 |

## orgmode.nvim（org-mode）

[nvim-orgmode/orgmode](https://github.com/nvim-orgmode/orgmode) による Emacs org-mode の移植。
見出し記号の整形は [nvim-orgmode/org-bullets.nvim](https://github.com/nvim-orgmode/org-bullets.nvim) が担う。
spec は [`lua/plugins/orgmode.lua`](lua/plugins/orgmode.lua)。

`.org` filetype のバッファで遅延ロード。org ファイルは `~/org/` 以下に置き、キャプチャの既定ノートは `~/org/inbox.org`。

### キーマップ

すべて `.org` バッファ内で有効（一部は任意のバッファから呼び出し可）。

#### アジェンダ・キャプチャ

| キー | 説明 |
| --- | --- |
| `<leader>oa` | アジェンダビューを開く |
| `<leader>oc` | キャプチャ（org-capture 相当）を起動 |

#### ファイル内移動・編集

| キー | 説明 |
| --- | --- |
| `<Tab>` | 見出しの折り畳みをトグル |
| `<S-Tab>` | すべての折り畳みをグローバルにトグル |
| `<localleader>i` | タイムスタンプを挿入 |
| `<localleader>t` | TODO 状態をサイクル |
| `<localleader>p` | 優先度をサイクル |
| `<localleader>n` | アーカイブ |
| `<CR>`（リンク上） | リンクを開く |
| `[[` | リンクを挿入 |

> `<localleader>` は `\`（バックスラッシュ）。

#### 日付・スケジュール

| キー | 説明 |
| --- | --- |
| `<localleader>s` | `SCHEDULED:` を設定 |
| `<localleader>d` | `DEADLINE:` を設定 |

### コマンド

| コマンド | 説明 |
| --- | --- |
| `:OrgAgenda` | アジェンダビューを開く |
| `:OrgCapture` | キャプチャを起動 |

### ファイル配置

```text
~/org/
├── inbox.org   -- キャプチャの既定ノート
├── todo.org    -- タスク管理
└── ...         -- アジェンダ対象（~/org/**/* を自動検索）
```

> `~/org/` ディレクトリがなければ初回起動前に作成しておく（`mkdir ~/org`）。
