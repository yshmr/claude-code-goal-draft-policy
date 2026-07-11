# 説明文のトリガー精度 — 2026-07 再評価(日本語10問追加・30問)

## メタデータ
- 判定者モデル: claude-sonnet-5(3名、独立、Agentツール `subagent_type: general-purpose`、互いの出力は非公開)
- 実行日: 2026-07-11
- スキル版(コミットハッシュ): `2b3b7ff`
- プロンプト: 本リポジトリ `handoff/PHASE-2-eval-expansion.md` §2.2 に記載の逐語プロンプトをそのまま使用
  (`<<DESCRIPTION>>` は SKILL.md フロントマターの description、`<<QUERIES>>` は `../trigger-eval.json` の
  30クエリを `1. <query>` 形式で番号付き列挙したもの)

## 評価セット
`../trigger-eval.json`(30問): should-trigger 英語10問+日本語5問、should-not-trigger 英語10問+日本語5問。
日本語10問は今回新規追加。

## 結果表

| # | lang | 期待 | J1 | J2 | J3 | 多数決 | 正誤 |
|---|------|------|----|----|----|--------|------|
| 1 | en | yes | yes | yes | yes | yes | ✅ |
| 2 | en | yes | yes | yes | yes | yes | ✅ |
| 3 | en | yes | yes | yes | yes | yes | ✅ |
| 4 | en | yes | yes | yes | yes | yes | ✅ |
| 5 | en | yes | yes | yes | yes | yes | ✅ |
| 6 | en | yes | yes | yes | yes | yes | ✅ |
| 7 | en | yes | yes | yes | yes | yes | ✅ |
| 8 | en | yes | yes | yes | yes | yes | ✅ |
| 9 | en | yes | yes | yes | yes | yes | ✅ |
| 10 | en | yes | yes | yes | yes | yes | ✅ |
| 11 | en | no | no | no | no | no | ✅ |
| 12 | en | no | no | no | no | no | ✅ |
| 13 | en | no | no | no | no | no | ✅ |
| 14 | en | no | no | no | no | no | ✅ |
| 15 | en | no | no | no | no | no | ✅ |
| 16 | en | no | no | no | no | no | ✅ |
| 17 | en | no | no | no | no | no | ✅ |
| 18 | en | no | no | no | no | no | ✅ |
| 19 | en | no | yes | no | no | no | ✅ |
| 20 | en | no | yes | yes | yes | **yes** | ❌ |
| 21 | ja | yes | yes | yes | yes | yes | ✅ |
| 22 | ja | yes | yes | yes | yes | yes | ✅ |
| 23 | ja | yes | yes | yes | yes | yes | ✅ |
| 24 | ja | yes | yes | yes | yes | yes | ✅ |
| 25 | ja | yes | yes | yes | yes | yes | ✅ |
| 26 | ja | no | no | no | no | no | ✅ |
| 27 | ja | no | no | no | no | no | ✅ |
| 28 | ja | no | no | no | no | no | ✅ |
| 29 | ja | no | yes | yes | yes | **yes** | ❌ |
| 30 | ja | no | no | no | no | no | ✅ |

誤判定2件:
- **#20**(en)「explain how the /goal evaluator decides whether a condition has been met」— 3名中3名が yes
  (説明質問を「条件作成」の一種と拡大解釈)。
- **#29**(ja)「/goal と /loop の違いって何？どっちを使うべき？」— 3名中3名が yes(同種の拡大解釈。
  比較質問を「作成支援」寄りに読んだと見られる)。

いずれも「`/goal` の挙動・違いを説明する質問」で、既存の設計判断(このスキルは条件を*作成する*ものであり
*解説する*ものではない)に反する誤トリガー。

## 精度・再現率・正確度

**全体(30問)**
- Precision: 15/17 = 88.2%
- Recall: 15/15 = 100%
- Accuracy: 28/30 = 93.3%

**日本語のみ(10問)**
- Precision: 5/6 = 83.3%
- Recall: 5/5 = 100%
- Accuracy: 9/10 = 90.0%

## 前回との比較
前回(`../desc-opt/trigger-results.md`、2026-07-09実行、20/20)は判定者=セッションモデル(Fable 5)。
今回は判定者=claude-sonnet-5であり、**判定者モデルが異なるため新ベースラインとして扱う**
(直接比較不可)。

## 判断
ja 10問の誤りは1問(#29)で、判断基準「ja 10問で誤りが2問以下なら description は変更しない」を満たす。
**現行の description は変更しない。**

## 原因分析
誤判定2件はいずれも「/goal の説明・比較を尋ねる質問」に対する拡大解釈で、englishとjapaneseの両方で
対称に発生した(モデルやプロンプト言語に起因する偏りではなく、説明文自体の「Use this whenever the
user wants to set a goal...」という書き出しが、境界事例(説明質問)を作成依頼側に引き寄せやすい構造的
傾向と考えられる)。ただし ja エラー1問は許容基準内であり、過学習を避けるため今回は description に
手を入れない。
