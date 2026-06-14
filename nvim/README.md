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
