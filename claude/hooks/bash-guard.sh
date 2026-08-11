#!/usr/bin/env bash
# bash-guard.sh — PreToolUse(Bash) の門番。
#
# 破壊的コマンドと秘密情報への接触を、実際に走る「コマンドそのもの」に限って検知する。
# コミットメッセージ・grep の検索語・ヒアドキュメントの本文・行コメントは、
# 文字列として名が出るだけで実行されないため、素通しする。
#
# 判定の骨組み:
#   1. ヒアドキュメント本文を落とす（`bash <<EOF` のように解釈器へ流す本文だけは残す）
#   2. 簡易なシェル字句解析でトークンへ割る（クォート内は 1 トークン、行コメントは除去）
#   3. 破壊的コマンドは「コマンド位置のトークン」だけを見る（sudo / xargs 等の被せ物は剥がす）
#   4. 秘密情報は「パスの形をしたトークン」だけを見る（空白を含む文字列＝文章は見ない）
#
# stdin : PreToolUse の hook 入力 JSON
# stdout: 差し止めるときのみ permissionDecision=deny の JSON
set -uo pipefail

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

AWK_GUARD=$(
	cat <<'AWK'
# ---- 補助 -----------------------------------------------------------------
function basename(p,   b) { b = p; sub(/^.*\//, "", b); return b }

# ---- 1) ヒアドキュメント本文の除去 -----------------------------------------
# `cat <<EOF ... EOF` の本文は文書であって命令ではない。ただし `bash <<EOF` の
# ように解釈器へ流す本文は実際に走るので、そこだけは命令として残す。
function strip_heredocs(s,   n, lines, i, line, out, delim, keep, t, tmp, d, head) {
  n = split(s, lines, "\n"); out = ""; delim = ""; keep = 0
  for (i = 1; i <= n; i++) {
    line = lines[i]
    if (delim != "") {
      t = line; sub(/^[ \t]+/, "", t)
      if (t == delim) { delim = ""; continue }
      if (keep) out = out line "\n"
      continue
    }
    out = out line "\n"
    tmp = line
    gsub(/<<</, " ", tmp)                       # here-string は本文を持たない
    if (match(tmp, /<<-?[ \t]*("[^"]+"|'[^']+'|[A-Za-z0-9_.\/-]+)/)) {
      head = substr(tmp, 1, RSTART - 1)
      d = substr(tmp, RSTART, RLENGTH)
      sub(/^<<-?[ \t]*/, "", d); gsub(/["']/, "", d)
      delim = d
      keep = (head ~ /(^|[ \t;&|(])(ba|z|k|da|a)?sh([ \t]|$)/ ||
              head ~ /(^|[ \t;&|(])(python[0-9.]*|node|perl|ruby|php)([ \t]|$)/) ? 1 : 0
    }
  }
  return out
}

# ---- 2) 字句解析 -----------------------------------------------------------
# TOKV[k] トークン本文 / TOKC[k] コマンド位置なら 1 / BARE クォート外の素の文字列
function push() {
  if (!HAS) return
  NTOK++; TOKV[NTOK] = CUR; TOKC[NTOK] = ATCMD
  if (CUR ~ /^-(exec|execdir|ok)$/) NEXTCMD = 1   # find -exec の後ろは命令
  CUR = ""; HAS = 0; ATCMD = NEXTCMD; NEXTCMD = 0
}
# "..." の中の $( ) / `` の本文を SUBS へ退避し、その次の位置を返す
function grab_subst(s, i, len,   c, d, body, tick) {
  tick = (substr(s, i, 1) == "`")
  i += (tick ? 1 : 2); d = 1; body = ""
  while (i <= len) {
    c = substr(s, i, 1)
    if (tick) { if (c == "`") { i++; break } }
    else {
      if (c == "(") d++
      else if (c == ")") { d--; if (d == 0) { i++; break } }
    }
    body = body c; i++
  }
  SUBS = SUBS body "\n"
  return i
}
function tokenize(s,   i, len, c, c2, j) {
  NTOK = 0; CUR = ""; HAS = 0; ATCMD = 1; NEXTCMD = 0; BARE = ""; SUBS = ""
  len = length(s); i = 1
  while (i <= len) {
    c = substr(s, i, 1)
    if (c == "\\") { CUR = CUR substr(s, i + 1, 1); HAS = 1; i += 2; continue }
    if (c == SQ) {                                # '...' は丸ごと 1 トークン
      j = index(substr(s, i + 1), SQ)
      if (j == 0) { CUR = CUR substr(s, i + 1); i = len + 1 }
      else { CUR = CUR substr(s, i + 1, j - 1); i = i + j + 1 }
      HAS = 1; BARE = BARE " "; continue
    }
    if (c == DQ) {                                # "..." も丸ごと 1 トークン
      i++
      while (i <= len) {
        c2 = substr(s, i, 1)
        if (c2 == "\\") { CUR = CUR substr(s, i + 1, 1); i += 2; continue }
        if (c2 == DQ) { i++; break }
        # "..." の中でもコマンド置換は走る。本文は別立てで後から調べる
        if ((c2 == "$" && substr(s, i + 1, 1) == "(") || c2 == "`") {
          i = grab_subst(s, i, len); continue
        }
        CUR = CUR c2; i++
      }
      HAS = 1; BARE = BARE " "; continue
    }
    if (c == "#" && !HAS) {                       # 行コメント
      while (i <= len && substr(s, i, 1) != "\n") i++
      continue
    }
    if (c == " " || c == "\t") { push(); BARE = BARE c; i++; continue }
    if (c == "\n" || c == ";" || c == "&" || c == "|" ||
        c == "(" || c == ")" || c == "{" || c == "}" || c == "`") {
      push(); ATCMD = 1; NEXTCMD = 0; BARE = BARE c; i++; continue
    }
    CUR = CUR c; HAS = 1; BARE = BARE c; i++
  }
  push()
}

# ---- 3) 破壊的コマンドの検知 -----------------------------------------------
function seg_check(from, to,   k, w, b, a) {
  k = from
  while (k <= to) {
    w = TOKV[k]
    if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { k++; continue }        # 変数代入の前置き
    b = basename(w)
    if (b ~ /^(sudo|doas|env|command|builtin|exec|nohup|nice|ionice|time|timeout|stdbuf|setsid|xargs)$/) {
      k++                                                        # 被せ物を剥がす
      while (k <= to && (TOKV[k] ~ /^-/ || TOKV[k] ~ /^[0-9]+[smhd]?$/)) k++
      continue
    }
    break
  }
  if (k > to) return ""
  b = basename(TOKV[k])
  if (b == "rm") {
    for (a = k + 1; a <= to; a++)
      if (TOKV[a] ~ /^-[A-Za-z]*[rR]/ || TOKV[a] == "--recursive") return "rm による再帰削除"
  } else if (b == "dd") {
    for (a = k + 1; a <= to; a++)
      if (TOKV[a] ~ /^(if|of)=/) return "dd による直接読み書き"
  } else if (b ~ /^mkfs(\.|$)/) {
    return "mkfs によるファイルシステム作成"
  }
  return ""
}
function destructive_check(   k, start, r) {
  for (k = 1; k <= NTOK; k++) {
    if (TOKC[k] != 1 && k != 1) continue
    start = k
    while (k + 1 <= NTOK && TOKC[k + 1] != 1) k++
    r = seg_check(start, k)
    if (r != "") return r
  }
  if (BARE ~ /:[ \t]*\(\)[ \t]*\{/) return "fork bomb"           # :(){ :|:& };:
  return ""
}

# ---- 4) 秘密情報への接触の検知 ---------------------------------------------
function is_secret(p,   b) {
  b = basename(p)
  if (b ~ /^\.env$/ || b ~ /^\.env\./) {
    if (b ~ /\.(example|sample|template|dist|defaults?|schema)$/) return 0   # 見本は除く
    return 1
  }
  if (b ~ /^id_(rsa|dsa|ecdsa|ed25519)$/) return 1               # .pub は公開鍵なので除く
  if (b ~ /\.pem$/ || b ~ /\.tfstate(\.backup)?$/) return 1
  if (b == ".npmrc" || b == ".pypirc" || b == ".netrc" || b == ".vault-token") return 1
  if (p ~ /(^|\/)\.ssh(\/|$)/ || p ~ /(^|\/)\.aws(\/|$)/ ||
      p ~ /(^|\/)\.gnupg(\/|$)/ || p ~ /(^|\/)\.azure(\/|$)/ ||
      p ~ /(^|\/)\.config\/gcloud(\/|$)/ || p ~ /(^|\/)\.config\/gh(\/|$)/ ||
      p ~ /(^|\/)\.kube\/config(\/|$)/ || p ~ /(^|\/)\.docker\/config\.json$/) return 1
  return 0
}
function secret_check(   k, v) {
  for (k = 1; k <= NTOK; k++) {
    v = TOKV[k]
    if (v == "" || v ~ /[ \t\n]/) continue                       # 空白を含む＝文章・検索語
    if (k > 1 && TOKV[k-1] ~ /^(-m|--message|-e|--regexp|--grep|-p|--pattern|--author|-S|-G)$/) continue
    if (v ~ /^-/) {                                              # オプション
      if (v !~ /=/) continue
      sub(/^[^=]*=/, "", v)
      if (v !~ /\//) continue                                    # パスの形でなければ検索語
    }
    if (is_secret(v)) return v
  }
  return ""
}

# ---- 入口 ------------------------------------------------------------------
BEGIN { SQ = sprintf("%c", 39); DQ = sprintf("%c", 34) }
{ SRC = SRC (NR > 1 ? "\n" : "") $0 }
END {
  txt = strip_heredocs(SRC)
  for (depth = 0; txt != "" && depth < 8; depth++) {
    tokenize(txt)
    r = destructive_check(); if (r != "") { print "DESTRUCTIVE\t" r; exit }
    r = secret_check();      if (r != "") { print "SECRET\t" r; exit }
    txt = SUBS                            # クォート内のコマンド置換を次の周回で調べる
  }
}
AWK
)

verdict="$(printf '%s' "$cmd" | awk "$AWK_GUARD" 2>/dev/null)"
[ -n "$verdict" ] || exit 0

kind="${verdict%%$'\t'*}"
detail="${verdict#*$'\t'}"
case "$kind" in
DESTRUCTIVE) reason="破壊的なコマンド（${detail}）を検知したため、実行を差し止めました。影響範囲をご確認のうえ、別の手立てをご検討くださいませ。" ;;
SECRET) reason="秘密情報（${detail}）への接触を検知したため、実行を差し止めました。" ;;
*) exit 0 ;;
esac

jq -cn --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
