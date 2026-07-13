# claude-code-goal-draft-policy

[Claude Code](https://code.claude.com) の **Skill** です。`/goal` の完了条件
（Claude Code が「Xが終わるまでターンをまたいで自律的に作業し続ける」ループを駆動する条件）
の作成・添削・修復を支援します。

> **`/goal` とは？** `/goal <条件>` は完了条件を設定するコマンドで、各ターン後に小型の
> 高速モデルが条件充足を判定し、未達なら Claude が自分で次のターンを開始します。
> Claude Code **v2.1.139（2026-05-11）** で追加されました。
> 公式ドキュメント: <https://code.claude.com/docs/en/goal>

## なぜ必要か

曖昧な条件は、いつまでも完了しない（ターンを浪費する）か、誤って完了する
（Claude が「達成」と主張し評価器がそれを信じる）かのどちらかになります。核心の制約は、
**評価器はツールを実行せず、会話にテキストとして出た内容だけで判定する**という点です。
したがって良い条件は、トランスクリプトから直接検証できるものでなければなりません。

このスキルは、ざっくりした依頼を **そのまま貼れる `/goal ...` 一行** に変換します。
条件は5つの要素で構成します:

1. **終了状態（End state）** — 測定可能で真偽が付く1つのゴール
2. **証明コマンド（Proof command）** — リポジトリを調べて見つけた実在するコマンド（推測しない）
3. **証拠シグナル（Evidence signal）** — 成功を示す正確な出力（`0 failed`、`exit 0`、`no matches` など）
4. **ガードレール（Guardrail）** — 途中で壊してはいけないもの（例: テストファイルを編集しない）
5. **停止句（Stop clause）** — 達成不能な条件が無限に走らないためのターン上限／停滞検知

既存のゴール（「なぜ完了しないのか？」）の **添削・修復** もできます。

## インストール

スキルフォルダを個人スキルディレクトリにコピーします:

```bash
# macOS / Linux
cp -r goal-draft-policy ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse goal-draft-policy $env:USERPROFILE\.claude\skills\
```

これで、自律的で検証可能な終了状態を持つ作業を依頼したときに自動で発火します。
直接呼び出す場合は `/goal-draft-policy`。（Skills対応の Claude Code が必要。`/goal` 自体は
v2.1.139以降が必要です。）

## 出所ラベル（Provenance labels）

`/goal` に関する公式情報はドキュメント1ページのみで、**条件作成のための公式スキルは存在しません**。
そこで `SKILL.md` は事実と独自の合成を分離し、各セクションにラベルを付けています:

- **`[official]`** — ドキュメントに明記（[`references/official-goal-reference.md`](goal-draft-policy/references/official-goal-reference.md) に蒸留）
- **`[method]`** — 公式事実の上に構築した、このスキル独自の手法
- **`[inference]`** — ドキュメントが確認していない推論。断定せず扱う
- **`[tested]`** — 小規模な実験で確認済み（[`references/evaluator-behavior-tests.md`](goal-draft-policy/references/evaluator-behavior-tests.md) にログ）

## リポジトリ構成

```
goal-draft-policy/          インストール可能なスキル本体
  SKILL.md                  作成メソッド（出所ラベル付き）
  references/
    official-goal-reference.md    公式 /goal ドキュメントの蒸留   [official]
    evaluator-behavior-tests.md   [tested] の根拠となる実験ログ
  evals/evals.json          テストケース

evaluation/                 スキルの検証記録（透明性のため）
  README.md                 評価の正典・置換関係の索引（current / historical / contaminated / E2E）← まずここを読む
  iteration-1/              標準ケース  — スキルあり100% / なし58%
  iteration-2/              罠ケース    — スキルあり100% / なし約82%（一部セル汚染。iteration-2-rerunで置き換え）
  iteration-2-rerun/        iteration-2 の汚染セルのクリーン再実行（モデル記録あり）
  iteration-3/              日本語・モノレポの新ケース
  iteration-4/              Go・質問分岐・過剰修復抑制の新ケース+eval-6再実行（フェーズ3編集後）
  iteration-5/               ask-branch強化後のeval-9再実行(n=3)+evals 0–3のモデル記録付き再実行
  e2e-2026-07/              実機 /goal ループのE2E記録（フェーズ6: 条件・ログ・verdict）
  probes-2026-07/           評価器プローブ（Exp 2–6）の生ログ
  trigger-eval.json         30問のトリガー評価セット（近似ミス＋日本語10問を含む）
  desc-opt/trigger-results.md          初回（20問）のトリガー精度結果
  desc-opt/trigger-results-2026-07.md  2026-07再評価（30問、判定者モデル記録あり）

docs/
  future-work.md            未検証項目＋ロードマップ＋外部指摘ログ（canonical な TODO）
  publication-safety.md     公開前の混入検査チェックリスト（(b) repository publication safety）
scripts/
  check-publication-safety.sh   公開前スキャナ（秘密情報・ローカルパス・session ID・raw JSONL 等）

handoff/                    フェーズ実行仕様書（設計セッションからの引き継ぎ。参照元であり再解釈しない）
```

> 注: `SKILL.md`・`references/`・`evaluation/` 配下の `goal.md`（eval出力）・`trigger-eval.json`
> などは、Claudeが読む動作定義／実際に生成・実行された記録として **英語のまま** 保持しています。

## 検証サマリー（と正直な注意点）

> **現行の正典（current authority）と歴史的結果（historical result）を先に区別してください。**
> 最新のモデル記録付き再評価は with_skill **85%** / baseline **83%**（`evaluation/iteration-5/`、
> claude-sonnet-5・2026-07-12）で、両者は**ほぼ拮抗**しています。これが現行の正典です。
> 以下に出てくる「**100% vs 58%**」などはモデル**未記録の旧ラン（historical / legacy）**の数値で、
> 被験体モデルが不明なため現行値と**直接比較できません**（削除も再採点もせず、履歴として保持）。
> どの記録が current / historical / contaminated / E2E authority かは
> **[`evaluation/README.md`](evaluation/README.md)** に索引化しています。まずそこを読むと迷いません。
> **このスキルは Skill 優位を保証しません。** 数値は強い示唆であって保証ではありません。
> 未検証項目・今後の予定は [`docs/future-work.md`](docs/future-work.md)。

このスキルは書いただけでなく、計測しています:

- **出力品質** — 実際のfixtureに対しスキルあり／なしのランを実行。スキルは2イテレーション通じて
  **100%**（CI設定とpackage.jsonの食い違い・スコープ詐称・リポジトリ無しのケースを含む）。
  一方スキルなしのベースラインは、停止句・最新ターンのアンカー・ガードレールを毎回落とし、
  時には「do not stop until…（〜するまで止まるな）」という、まさにこのツールが防ぐべき暴走条件を書きました。
  （この「58%」はモデル未記録の旧ランに基づく数値です。モデル記録付きの再実行は
  `evaluation/iteration-5/` を参照 — 新ベースラインでは with/without の差はここまで大きくありません。）
- **トリガー（初回・20問）** — 3名の独立した判定者が、難しめの近似ミス（`/loop`、Stopフック、Agent SDK、
  OKR、単発実行）を含むセットで説明文を **20/20** と評価しました。
- **iteration-2-rerun（汚染除去後のクリーン再実行）** — eval-4（スコープ詐称のハーデニング）・eval-5
  （リポジトリ無しの成果物ゴール）とも、被験体モデル claude-sonnet-5 でスキルあり **9/9 = 100%**、
  ベースラインも **9/9 = 100%**（この2ケースは元々批評/修復タスクで、ベースライン単体でも
  同水準の厳密さを再現しやすいことが分かった）。
- **iteration-3（日本語・モノレポの新ケース）** — 日本語での `/goal` 作成（eval-6）はスキルあり
  **6.5/7**・ベースライン **6.5/7** の引き分け。モノレポ（eval-7、コマンド候補が複数・CI無し）は
  スキルあり **6/6**・ベースライン **4.5/6** ── ベースラインは実在しない Vitest の `0 failed`
  という文字列を証拠シグナルとして要求してしまい、スキルの価値が明確に出た。
- **トリガー（2026-07再評価・30問、日本語10問追加）** — 判定者3名（claude-sonnet-5）の多数決で
  全体 **28/30**（precision 88.2% / recall 100% / accuracy 93.3%）、日本語のみ **9/10**
  （precision 83.3% / recall 100% / accuracy 90.0%）。誤りは2件とも「`/goal` の説明・比較を尋ねる
  質問」への拡大解釈で、日本語10問中の誤りが許容基準（2問以下）内のため description は変更していない。
- **プローブ第2弾（フェーズ3、実行日 2026-07-12）** — 停滞検知句・ガードレールの提示エビデンス・
  幻の証拠シグナル・時間上限・AND チェックリストの5点を新規に検証し、結果をすべて SKILL.md に
  反映（例: 停滞検知句「同じ失敗が2回再発」は自己申告なしでも3/4で発火し、進捗中の誤発火は0/4。
  要求した `git diff --stat` に現れた違反は、ナレーションが沈黙でも虚偽の遵守主張でも4/4で検出。
  時間上限は経過時間を毎ターン明示すれば4/4完了、無ければ0/4）。生ログは
  `evaluation/probes-2026-07/raw-log.md`、詳細は `references/evaluator-behavior-tests.md` を参照。
- **iteration-4（Go・質問分岐・過剰修復抑制、実行日 2026-07-12）** — Go モジュールの証拠シグナル
  一般化（eval-8）は **6/6 vs 6/6 の引き分け**（with/without ともに `go test ./...` の実出力形式
  `ok`/`FAIL` を正確に踏まえ、Vitest のような罠に落ちなかった）。測定不能な依頼への質問分岐
  （eval-9）は **3.5/5 vs 4/5 でベースラインが上回った** — with_skill が SKILL.md の分岐ルールに
  反して質問せずに代理指標を自分で確定してしまった一方、baseline は設定前のユーザー確認を明確に
  求めた。健全なゴールへの過剰修復抑制（eval-10）は **5/5 vs 5/5 の引き分け**（両セルとも
  健全要素を壊さず、実機検証済みの事実のみを指摘）。
- **eval-6 再実行（テンプレート格上げの効果検証）** — フェーズ3で SKILL.md に追加した
  「`State the turn number each turn.` を必須項目に格上げ」の効果が実測で確認できた。
  iteration-3 では with_skill もターン番号明示を欠き ⚠️ だった項目が、今回は ✅ に変わった
  （**7/7**、baseline は停止句自体を欠く出力で **4.5/7**）。
- **iteration-5（ask-branch強化後のeval-9再実行 n=3 + evals 0–3のモデル記録付き再実行、実行日
  2026-07-12）** — SKILL.md の分岐ルールを「質問だけを返す」停止指示に強化した結果、eval-9
  （測定不能な依頼への質問分岐）は with_skill が **5.0/5（#2=✅ 3/3本）**、baseline は
  **3.67/5（#2=✅ 0/3、⚠️2/❌1）** となり、`ASKFIX = EFFECTIVE` と判定（フェーズ4の修正前
  3.5/5 から明確に改善）。evals 0–3 のモデル記録付き再実行（claude-sonnet-5, effort medium,
  各セル n=1）は **with_skill 20.5/24（85%）・baseline 20/24（83%）** とほぼ拮抗 — 現行の強力な
  ベースモデルは指示なしでもリポジトリ探索・CI参照・ガードレール追加をかなりの水準でこなせるが、
  eval-3（CI緑判定）では baseline がターン上限のない暴走条件を書いた一方 with_skill は健全な
  停止句を含めた。詳細は `evaluation/iteration-5/benchmark.md`。
- **実機E2E（フェーズ6、実行日 2026-07-12、Claude Code 2.1.206）** — 本物の `/goal` ループで
  2条件をヘッドレス実測。達成可能ゴール（Run A）は新鮮な緑のテスト出力が画面に出た後にのみ
  完了（1ターン・30秒・評価器1,323トークン）、達成不能ゴール+OR結合停止句（Run B）は
  ターン上限3でstop句が発火しブロッカー要約つきで終了（+確認1評価の計4評価・2分10秒）。
  事前登録したプローブ予測（P1〜P5）と**すべて一致**し、実評価器の理由文はOR分岐の列挙・
  diff証拠によるガードレール検証・証拠文字列の逐語引用というプローブと同じ推論様式を示した。
  記録は `evaluation/e2e-2026-07/`（verdict.md に判定表と実行方法の逸脱を明記）。
- **2026-07以降の全ランは、被験体モデル・実行日・スキル版（コミットハッシュ）を記録しています。**

正直な注意点: トリガー検証は実際の `available_skills` 発火機構の **近似** です。評価器の実験は
**再構成した** 評価器プロンプトと小さいサンプルサイズを用いています（実機E2Eでは2条件のみ
整合を確認済み — `evaluation/e2e-2026-07/`）。iteration-2のベースラインの
一部は条件が混入しています（`iteration-2-rerun/` でクリーンに再実行済み）。数値は強い示唆であって
保証ではありません。（公式の `skill-creator` 最適化ループはこの環境では数値を出せませんでした ──
サブプロセスのパイプに対する `select.select()` というWindows移植性バグのため。原因分析メモを参照。）
なお2026-07の判定者・被験体はいずれも claude-sonnet-5 であり、モデルを記録していない旧イテレーション
（iteration-1・iteration-2の初回実行、および初回トリガー評価）の数値とは直接比較できません。
iteration-4 も各セル n=1 の単発ランであり、判定者=被験体=claude-sonnet-5 の同一性も同様です
（eval-9 では実際に with_skill が負けており、スキルの優位は保証ではなく傾向として読んでください）。

## 免責事項

Anthropic とは無関係で、公認もされていません。公開ドキュメントと作者自身の実験に基づいて構築しており、
`[inference]`／`[tested]` の部分は公式ではありません。[公式ドキュメント](https://code.claude.com/docs/en/goal)
で検証してください。両者が食い違う場合は公式が優先されます。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
