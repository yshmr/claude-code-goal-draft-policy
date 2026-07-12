「非エンジニアが読んで分かるようになるまで」は、そのままだと `/goal` の完了条件にできません。理由を先に説明させてください。

## なぜそのままではダメか

`/goal` の判定役はツールを一切使わない小型モデル（Haiku）で、各ターン後に**会話の文字起こしだけ**を読んで yes/no を決めます（ファイルを開いたり、実際に非エンジニアに読ませたりはできません）。「非エンジニアが分かる」は、

- 文字起こしから機械的に確認できる基準がない（「分かる」の閾値が定義できない）
- このリポジトリには README の品質を測るツール（linter、readability チェッカーなど）が一つも無い（`package.json` すら無く、中身は `README.md` と `src/gateway.js` のみ）

という二重の意味で判定不能です。このまま `/goal` にすると、Claude が「わかりやすく書き直しました」と言い張るだけで通ってしまうか、逆に何をもって終わりか分からず turn を消費し続けるかのどちらかになります。

## 代わりに提案する測定可能な代理指標（proxy）

「非エンジニアが読める」を厳密に測る術は無いので、現実的な代理として次の3点をチェック可能な形に落としました。ご自身の意図とズレていれば、リストを調整してから使ってください。

1. 冒頭に **平易な要約セクション**（`## Overview`）を追加し、そこには専門用語を一切使わない
2. 残りの専門用語はすべて **`## Glossary`** セクションで定義する
3. 既存の運用上重要な事実（env 変数名や閾値など）は**削除しない**（書き直しで情報が失われないようにするガードレール）

以下がその条件です。

```
/goal README.md が非エンジニア向けの説明を満たす。具体的には (a) README.md に
"## Overview" という見出しのセクションがあり、その本文2〜4文が mTLS, JWT,
RFC 7519, sidecar, envoy, circuit-breaking, SLO, helm, OPA, configmap, port-forward,
healthz, bearer, thundering herd, retry budget のどれも含まない、かつ (b) README.md
に "## Glossary" という見出しのセクションがあり、上記14語それぞれについて
その語を含む定義行がある、かつ (c) README.md に
GW_UPSTREAM_TIMEOUT_MS, GW_RETRY_BUDGET, GW_JWT_AUD, GW_OTEL_EP という4つの
文字列と "0.3" が元のまま残っている。直近のターンで、次を実行して証拠を示すこと:
`grep -n "^## Overview" README.md`、Overview セクション本文を抽出して
`grep -icE "mTLS|JWT|RFC 7519|sidecar|envoy|circuit-breaking|SLO|helm|OPA|configmap|port-forward|healthz|bearer|thundering herd|retry budget"` を実行し出力が 0 であることを示す、
`grep -n "^## Glossary" README.md`、Glossary セクション本文に対して上記14語それぞれ
`grep -c` が1以上であることを示す、`grep -cF "GW_UPSTREAM_TIMEOUT_MS" README.md`
`grep -cF "GW_RETRY_BUDGET" README.md` `grep -cF "GW_JWT_AUD" README.md`
`grep -cF "GW_OTEL_EP" README.md` `grep -cF "0.3" README.md` が全て1以上であること
を示す — または15ターンで停止する、または Overview 本文中の専門用語カウントが
2ターン連続で減らない場合は停止し、直前の状態と残っている専門用語を要約して報告する。
src/gateway.js の内容は変更しない — 各ターン `git diff --stat -- src/` が空である
ことを示す。各ターンで「turn k of 15」を明示する。
```

## 補足

- この条件は「本当に非エンジニアが理解できるか」を保証しません。あくまで「専門用語ゼロの要約＋用語集がある」という機械的に確認できる代理です。もし本当の読みやすさ検証がしたいなら、判定は `/goal` の自動ループではなく、人間（非エンジニアの同僚など）に実際のREADMEを読んでもらってフィードバックをもらう工程を挟むのが確実です。
- 用語リストはこの README に実際に出てくる専門用語から拾いました。書き直しで新しい専門用語（例えば別の略語）が増えた場合、その語は Glossary チェックの対象外になるので、Claude が用語集を作っても漏れが出る可能性があります。気になる場合は「本文に出てくる大文字略語・専門用語はすべて Glossary に定義する」のような一般化条件に変えることもできますが、Haiku 判定役がその判定を安定して行えるかは未検証です。
- このリポジトリは npm/pytest 等のビルド・テストツールを持たないため、証拠はすべて `grep` ベースにしています。実行環境に `grep` が無い場合は `rg`（ripgrep）に置き換えてください。
- shell コマンドを実行する `/goal` は、`acceptEdits` または `bypassPermissions` モードでないと承認プロンプトで止まる点にご留意ください。
