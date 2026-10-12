# 情報源ごとの検索と取得

2026 年 10 月に各公式ドキュメントと実際の応答で確かめた内容である。
「未確認」と書いた項目は、使う前に一度、実際の応答で確かめる。

## 目次

1. ACL Anthology
2. AI 系の proceedings（NeurIPS、ICLR、ICML、COLM、TMLR、AAAI、IJCAI）
3. arXiv
4. 横断検索（Semantic Scholar、DBLP、OpenAlex）
5. 採録先の確かめ方
6. 取得時の制約

## 1. ACL Anthology

### ID と URL

- 新形式の ID は `<年>.<会場>-<巻>.<番号>`（例：`2024.acl-long.1`、`2020.acl-main.123`、`2023.findings-emnlp.45`）。旧形式は `P19-1001`（会議）、`W19-5001`（workshop）、`Q19-1001`（TACL）、`J19-1001`（Computational Linguistics）。旧形式の ID も URL に使える。
- 論文ページ（アブストラクトを含む）：`https://aclanthology.org/<ID>/`
- PDF：`https://aclanthology.org/<ID>.pdf`
- BibTeX：`https://aclanthology.org/<ID>.bib`
- DOI：`10.18653/v1/<ID>`
- 巻：`https://aclanthology.org/volumes/<巻 ID>/`、巻の BibTeX は `https://aclanthology.org/volumes/<巻 ID>.bib`
- 会議の回：`https://aclanthology.org/events/<会場>-<年>/`（例：`events/acl-2024/`）
- 会場の年別一覧：`https://aclanthology.org/venues/<会場>/`
- 論文ページには arXiv へのリンクがない。arXiv 版との対応は Semantic Scholar で取る（5 節）。

### 会場と巻 ID

- 会場の略号：`acl`、`emnlp`、`naacl`、`eacl`、`aacl`、`ijcnlp`、`coling`、`lrec`、`conll`、`starsem`（*SEM）、`tacl`、`cl`（Computational Linguistics）、`findings`、`semeval`、`wmt`。
- ACL 2024 の巻の例：本会議は `2024.acl-long`、`2024.acl-short`、`2024.acl-demos`、`2024.acl-srw`。Findings は `2024.findings-acl`。workshop は `2024.bionlp-1` など。
- 2020〜2022 年の ACL 本会議は `2020.acl-main` のように long と short を分けない。
- Findings は 2020 年の EMNLP から始まった本会議とは別の巻で、`findings` の会場に属する。サーベイでは本会議と区別して記録する。
- TACL、CL、LREC-COLING 2024、*SEM の巻 ID の書式は未確認。

### 検索

- サイト内検索は Google カスタム検索で、会場、年、著者による絞り込みはできず、WebFetch では結果を取れない。
- 主題で探すときは、Semantic Scholar の会場で絞った検索（4 節）か、WebSearch の `allowed_domains: ["aclanthology.org"]` を使う。
- 特定の会議の回を網羅して走査するときは、会議の回のページか巻の BibTeX を取得する。どちらも数十万字あり、WebFetch は一度に約 10 万字までしか読まないので、`offset` で分けて読む。EMNLP 2025 の会議の回のページのように 10 MB を超えると取得に失敗する。そのときは巻ごとに取得する。
- 数年分を網羅するなら、公式の Python パッケージ `acl-anthology`（PyPI、Python 3.11 以上）が使える。`Anthology.from_repo()` は GitHub の acl-org/acl-anthology を clone するため、git と数百 MB の容量が要る。実行の前にユーザーの了承を得る。

  ```python
  # uv run --with acl-anthology script.py
  from acl_anthology import Anthology

  anthology = Anthology.from_repo()

  # 会議の回に属する巻の一覧
  for volume in anthology.get_event("acl-2024").volumes():
      print(volume.title)

  # 題名の索引はないので、全件を走査して絞る
  for paper in anthology.papers():
      if "retrieval-augmented" in str(paper.title).lower():
          print(paper.full_id, paper.title)
  ```

  論文一件は `anthology.get("<ID>")` で引き、`paper.to_bibtex(with_abstract=True)` で BibTeX を得る。
- 全件の BibTeX は `https://aclanthology.org/anthology.bib.gz`（アブストラクトなし）にある。アブストラクト付きの `anthology+abstracts.bib.gz` は FAQ に名前があるが、中身は未確認。

## 2. AI 系の proceedings

### NeurIPS

- 年別ページ：`https://proceedings.neurips.cc/paper_files/paper/<年>`
- 2025 年は構造が変わり、年別ページには Creative AI トラックしか並ばない。本会議、Position Paper、Datasets and Benchmarks は `https://proceedings.neurips.cc/paper_files/paper/2025/vol38-main-conference` にある。
- 論文のアブストラクトページ：`/paper_files/paper/<年>/hash/<32 桁の hex>-Abstract-Conference.html`。Datasets and Benchmarks は末尾が `-Abstract-Datasets_and_Benchmarks_Track.html`。
- PDF：`/paper_files/paper/<年>/file/<hash>-Paper-Conference.pdf`。BibTeX の URL は hash と別の内部 ID を使うので、アブストラクトページのリンクから拾う。
- 2021 年の Datasets and Benchmarks は別サイト `https://datasets-benchmarks-proceedings.neurips.cc/paper/2021` にある。
- OpenReview にも `NeurIPS.cc/<年>/Conference` の group があり、査読の議論はそちらで読める。

### ICLR

- 採択論文は `https://proceedings.iclr.cc/paper_files/paper/<年>` にある（2024 年以降。URL の構造は NeurIPS と同じ）。
- 一次の所在は OpenReview（`https://openreview.net/group?id=ICLR.cc/<年>/Conference`）で、査読、不採択、取り下げの論文も公開される。
- OpenReview API v2（`https://api2.openreview.net`）では、採択論文の `content.venueid` が会議の ID（例：`ICLR.cc/2025/Conference`）になる。不採択と取り下げの venueid は、会議の group の `content` にある `submission_venue_id`、`withdrawn_venue_id`、`desk_rejected_venue_id` から読む。
- 2026 年 10 月の時点で、匿名での API と PDF の取得は bot 検証（`openreview.net/challenge`）に遮られることがある。公式ドキュメントも API の利用にアカウントを求めている。ログインはせず、認証情報も求めない。採択論文は proceedings.iclr.cc で読み、OpenReview は取得できたときだけ補助に使う。
- Oral、Spotlight、Poster の区別を示す `content.venue` の文字列の形は未確認。

### ICML（PMLR）

- 巻番号：ICML 2026 は `v306`、2025 は `v267`、2024 は `v235`、2023 は `v202`、2022 は `v162`、2021 は `v139`、2020 は `v119`。
- 巻のページ：`https://proceedings.mlr.press/<巻>/`
- 論文ページ：`https://proceedings.mlr.press/<巻>/<key>.html`（key は `aamand25a` の形）
- PDF：論文ページのリンクは `https://raw.githubusercontent.com/mlresearch/<巻>/main/assets/<key>/<key>.pdf` を指す。
- 巻全体の BibTeX：`https://proceedings.mlr.press/<巻>/assets/bib/bibliography.bib`（数 MB）
- 2025 年以降の論文ページには OpenReview へのリンクがある。

### COLM、TMLR

- COLM（Conference on Language Modeling）：サイトは `https://colm.cc/`、過去の回は `https://colmweb.org/<年>/`。採択論文の一覧は `/Conferences/<年>/AcceptedPapers`。査読は OpenReview で行われる。
- TMLR：査読と公開はどちらも OpenReview（`https://openreview.net/group?id=TMLR`）。一覧は `https://jmlr.org/tmlr/papers/`、論文は `https://openreview.net/forum?id=<ID>`、BibTeX は `https://jmlr.org/tmlr/papers/bib/<ID>.bib`。Survey Certification の付いた論文は、既存のサーベイを探すときに当たる。

### AAAI、IJCAI

- AAAI：`https://ojs.aaai.org/index.php/AAAI/issue/archive`。AAAI-26 は Vol. 40 で、号の番号は連番でない。
- IJCAI：`https://www.ijcai.org/proceedings/<年>/`
- どちらも主題による検索は Semantic Scholar か DBLP で行う。

## 3. arXiv

### API

- エンドポイント：`http://export.arxiv.org/api/query`（Atom 形式で返る）
- 検索の接頭辞：`ti`（題名）、`abs`（アブストラクト）、`au`（著者）、`cat`（分類）、`co`（コメント）、`jr`（journal_ref）、`all`
- 演算子：`AND`、`OR`、`ANDNOT`。括弧は `%28` と `%29`、句の引用符は `%22`、空白は `+` で書く。
- 投稿日の範囲：`submittedDate:[202401010000+TO+202412312359]`（GMT、分の単位まで）
- 並べ替え：`sortBy=relevance|lastUpdatedDate|submittedDate`、`sortOrder=ascending|descending`
- ページ送り：`start` と `max_results`（1 回 2,000 件まで、合計 30,000 件まで）
- ID で引く：`id_list=2005.11401,2310.06825`
- 動作を確かめた例：

  ```text
  http://export.arxiv.org/api/query?search_query=cat:cs.CL+AND+ti:%22retrieval+augmented%22&max_results=50&sortBy=submittedDate&sortOrder=descending
  ```

- `cat:cs.CL` は cross-list の論文も拾う。主分類は応答の `arxiv:primary_category` で確かめる。
- `published` は v1 の日付、`updated` は最新版の日付である。

### 利用規約とレート制限

- 3 秒に 1 回まで、同時接続は 1 本まで。管理下のすべてのマシンの合計で数える。
- 検索の索引は 1 日に 1 回しか更新されないので、同じ検索を同じ日に繰り返さない。
- 403 や 429 を受けたら、間を置かずに再試行しない。連打は攻撃と見なされうる。
- 2025〜2026 年に、日付範囲の検索が 0 件を返す、句の検索が AND として扱われる、406 や 429 が断続的に返る、という報告が arXiv-api のメーリングリストにある。結果が不自然に少ないときは、条件を変えて確かめる。

### 論文の取得

- アブストラクトページ：`https://arxiv.org/abs/<ID>`（版の一覧と、著者のコメントが読める）
- PDF：`https://arxiv.org/pdf/<ID>v<版>`。版を付けなければ最新版になる。
- HTML 版：`https://arxiv.org/html/<ID>v<版>`。実験的な提供で、変換に誤りのある論文や HTML 版のない論文がある。数値は PDF で確かめる。
- ID の形式は `YYMM.NNNNN`（2015 年以降は 5 桁）。

### 分類

- `cs.CL`：計算言語学と NLP。主な検索先である。
- `cs.LG`：機械学習全般。`stat.ML`：統計的、理論的な機械学習。
- `cs.AI`：AI 全般。ただし視覚、ロボティクス、機械学習、言語は別の分類に入るので、それだけでは足りない。
- 主題によって `cs.IR`（情報検索）、`cs.CV`（視覚と言語）、`cs.SD` と `eess.AS`（音声）、`cs.CY`（社会的影響）を加える。

## 4. 横断検索

### Semantic Scholar Academic Graph API

ベース URL は `https://api.semanticscholar.org/graph/v1`。

- `/paper/search/bulk`：主題の検索に使う。1 回 1,000 件で、続きは応答の `token` で取る。`query` には `+`（AND）、`|`（OR）、`-`（NOT）、`"句"`、`*`（前方一致）、括弧が使え、題名とアブストラクトに当たる。
- `/paper/search`：関連度順の検索。1 回 100 件、上位 1,000 件まで。
- 絞り込み：`year=2022-2025`、`venue=<会場の正式名>`、`fieldsOfStudy=Computer Science`、`publicationTypes`、`openAccessPdf`
- 取得する項目は `fields` で指定する：`title,abstract,year,venue,publicationVenue,externalIds,authors,openAccessPdf`
- 動作を確かめた例（ACL 本会議の正式名で絞る）：

  ```text
  https://api.semanticscholar.org/graph/v1/paper/search/bulk?query="retrieval augmented"&venue=Annual Meeting of the Association for Computational Linguistics&year=2024&fields=title,venue,year,externalIds
  ```

  会場の文字列が本会議と Findings を区別するかは未確認。会場は ACL Anthology の ID で確かめ直す（5 節）。
- `/paper/search/match?query=<題名>`：題名に最も近い一件を返す。見つからなければ 404。
- `/paper/<ID>`：論文一件。ID は `ARXIV:2005.11401`、`ACL:2024.acl-long.1`、`DOI:<DOI>`、`CorpusId:<番号>` の形で書く。
- `/paper/<ID>/references`、`/paper/<ID>/citations`：backward と forward の snowballing に使う。1 回 1,000 件まで。
- `POST /paper/batch`：ID を 500 件までまとめて引く。
- API キーなしの利用は全利用者で共有する枠で、429 がよく返る。間を置いて再試行し、連打しない。API キーは扱わない。

### DBLP

- 検索 API：`https://dblp.org/search/publ/api?q=<語>&format=json&h=<件数>`（`h` は 1,000 まで）
- 空白は AND、`|` は OR、語の前方一致が既定。
- 2026 年 10 月の時点で、WebFetch からの取得は bot 対策に遮られることがあった。取得できたときの補助として使う。
- 結果の `key` が `conf/acl/...` なら会議版、`journals/corr/...` なら arXiv 版を表す。

### OpenAlex

- `https://api.openalex.org/works?search=<語>&filter=publication_year:2022-2025`
- arXiv 論文は DOI `10.48550/arXiv.<ID>` で引ける。
- 会場の情報が欠けた記録や、無関係な DOI の混入が見られた。補助にとどめる。

## 5. 採録先の確かめ方

arXiv のプレプリントがどの会議に採録されたかは、次の順に確かめる。

1. Semantic Scholar の `/paper/ARXIV:<ID>?fields=title,venue,year,publicationVenue,externalIds` を引く。`externalIds.ACL` があれば ACL Anthology の論文がある。`externalIds.DBLP` が `conf/` で始まれば会議の版がある。
2. `externalIds.ACL` があれば、`https://aclanthology.org/<ACL ID>/` を開き、本会議、Findings、workshop のどれかを巻 ID で確かめる。
3. AI 系の会議なら、proceedings の年別ページか OpenReview で題名を探し、採択の区分を確かめる。
4. arXiv の `comment` や `journal_ref`（「Accepted to ...」など）は著者の自己申告で、空のことも多い。手がかりにとどめる。
5. 題名が変わっている場合があるので、1 で見つからなければ `/paper/search/match` に題名を渡し、著者で照合する。

どれでも確かめられなければ「プレプリント（査読なし）」とする。

## 6. 取得時の制約

- WebFetch は取得した内容をモデルで要約して返す。一覧の取りこぼしや数値の丸めが起こりうる。一覧は件数を突き合わせ、数値は PDF で確かめる。
- WebFetch は一度に約 10 万字までしか読まない。続きは `offset` で読む。10 MB を超える応答は取得に失敗する。
- PDF の本文は、pdf-mcp に URL を直接渡して読める（`pdf_info`、`pdf_search`、`pdf_read_pages`）。
- curl と wget は承認制である。生の応答を保存したいときは、必要性を述べてから使い、保存先は作業用の一時ディレクトリにする。
- ログインが要る情報源にはログインせず、認証情報や API キーを求めない。
