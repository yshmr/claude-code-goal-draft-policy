# Evaluation index / 評価の正典と置換関係

`evaluation/` 配下の各記録について、**どれが現行（authoritative）で、何が何を
置き換えたか** を一覧にする。数値そのものは各 `benchmark.md` / ルートの
`README.md`「検証サマリー」を正典とし、ここは *どれを読むべきか* の索引に徹する。

> これは **現状**の索引。未検証項目・今後の予定は
> [`../docs/future-work.md`](../docs/future-work.md) を参照。

## 記録の世代（provenance）

2026-07 を境に記録の信頼度が変わる:

- **2026-07 以降のラン** — 被験体モデル・実行日・スキル版（コミットハッシュ）を
  すべて記録。相互比較可能。
- **旧ラン（legacy, モデル未記録）** — iteration-1、iteration-2 の初回実行、初回
  トリガー評価（`desc-opt/trigger-results.md`）。被験体モデル不明のため、
  2026-07 以降の数値とは **直接比較できない**。

いずれも判定者・被験体は（記録のある範囲で）claude-sonnet-5。判定者＝被験体の
同一性という限界は [`../docs/future-work.md`](../docs/future-work.md) L4 参照。

## ディレクトリ別・正典表

| ディレクトリ | 内容 | 世代 | 現行か | 置換関係 |
|--------------|------|------|--------|----------|
| `iteration-1/` | 標準ケース（evals 0–2） | legacy（未記録） | 部分的に旧 | evals 0–3 のモデル記録付き再実行は `iteration-5/` |
| `iteration-2/` | 罠ケース（evals 3–5） | legacy（未記録） | **一部汚染で旧** | eval-4/5 の汚染セルは `iteration-2-rerun/` で置換 |
| `iteration-2-rerun/` | eval-4/5 のクリーン再実行 | 記録あり | ✅ 現行 | `iteration-2/` の該当セルを置換 |
| `iteration-3/` | 日本語（eval-6）・モノレポ（eval-7） | 記録あり（2026-07） | eval-7 は現行 | eval-6 は `iteration-4/` の再実行が現行 |
| `iteration-4/` | Go（eval-8）・質問分岐（eval-9）・過剰修復抑制（eval-10）＋eval-6 再実行 | 記録あり（2026-07-12, n=1） | eval-6/8/10 は現行 | eval-9 は `iteration-5/` が現行（後述） |
| `iteration-5/` | ask-branch 強化後の eval-9 再実行（n=3）＋evals 0–3 のモデル記録付き再実行 | 記録あり（2026-07-12） | ✅ 現行 | eval-9 と evals 0–3 の正典 |
| `e2e-2026-07/` | 実機 `/goal` ループの E2E（2条件） | 記録あり（2026-07-12, CC 2.1.206） | ✅ 現行 | プローブ予測 P1–P5 の実機確認 |
| `probes-2026-07/` | 評価器プローブ Exp 2–6 の生ログ | 記録あり（2026-07-12） | ✅ 現行 | `SKILL.md` の `[tested]` の根拠 |
| `desc-opt/trigger-results.md` | 初回トリガー評価（20問） | legacy（未記録） | 旧 | `trigger-results-2026-07.md` が現行 |
| `desc-opt/trigger-results-2026-07.md` | トリガー再評価（30問、日本語10問） | 記録あり（2026-07, claude-sonnet-5） | ✅ 現行 | 初回20問を置換 |
| `trigger-eval.json` | トリガー評価セット（30問） | — | ✅ 現行 | — |

## ケース単位の「今どれを読むべきか」

置換が起きたケースだけ明示する（それ以外はディレクトリ表のとおり）:

| ケース | 現行の記録 | 置換された旧記録 | 置換理由 |
|--------|-----------|------------------|----------|
| eval-4 / eval-5 | `iteration-2-rerun/` | `iteration-2/` の該当セル | ベースラインセルに条件が混入していたためクリーン再実行 |
| eval-6（日本語） | `iteration-4/eval-6-japanese-post-edit/` | `iteration-3/eval-6-*` | テンプレ格上げ（ターン番号明示を必須化）の効果検証で ⚠️→✅ |
| eval-9（質問分岐） | `iteration-5/eval-9-ask-branch-post-fix/`（n=3） | `iteration-4/eval-9-*`（n=1, skill 敗北） | 分岐ルールを「質問だけ返す」停止指示に強化（`ASKFIX = EFFECTIVE`） |
| evals 0–3 | `iteration-5/`（モデル記録付き再実行） | `iteration-1/`・`iteration-2/` の初回 | 旧ランはモデル未記録で比較不能 |

## Synthetic data boundary

<!-- SYNTHETIC-DATA-DECLARATION (required; verified by scripts/check-eval-artifacts.sh) -->
**このリポジトリで公開する fixture・eval 出力・プローブログ・E2E ログはすべて合成
（synthetic）または再構成データであり、実在の人物・顧客・社内データ・実運用の生
トランスクリプトを含みません。** fixture の内容は `evaluation/fixtures.manifest.sha256`
に git blob ハッシュで固定され（`scripts/check-fixture-integrity.sh`）、記録後の
無断改変を CI が検知します。実 session/ローカル情報の混入は
[`../docs/publication-safety.md`](../docs/publication-safety.md) のスキャナで別途遮断します。
