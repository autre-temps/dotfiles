-- orgmode: Emacs org-mode の主要機能（アジェンダ・TODO・キャプチャ・折り畳み）を
-- .org ファイルとして Neovim 上に再現する。org-bullets で見出し記号を整形。
return {
	{
		"nvim-orgmode/orgmode",
		ft = "org",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {
			-- org ファイルの置き場。~/org/ 以下の .org を全て対象にする
			org_agenda_files = { "~/org/**/*" },
			org_default_notes_file = "~/org/inbox.org",
		},
	},
	{
		"nvim-orgmode/org-bullets.nvim",
		ft = "org",
		opts = {
			-- 見出しレベル 1〜8 を順に割り当てる記号
			symbols = { "◉", "○", "✿", "✤", "▶", "▸", "▹", "▫" },
		},
	},
}
