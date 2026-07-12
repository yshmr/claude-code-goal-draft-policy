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
  iteration-1/              標準ケース  — スキルあり100% / なし58%
  iteration-2/              罠ケース    — スキルあり100% / なし約82%（一部セル汚染。iteration-2-rerunで置き換え）
  iteration-2-rerun/        iteration-2 の汚染セルのクリーン再実行（モデル記録あり）
  iteration-3/              日本語・モノレポの新ケース
  iteration-4/              Go・質問分岐・過剰修復抑制の新ケース+eval-6再実行（フェーズ3編集後）
  probes-2026-07/           評価器プローブ（Exp 2–6）の生ログ
  trigger-eval.json         30問のトリガー評価セット（近似ミス＋日本語10問を含む）
  desc-opt/trigger-results.md          初回（20問）のトリガー精度結果
  desc-opt/trigger-results-2026-07.md  2026-07再評価（30問、判定者モデル記録あり）

handoff/                    フェーズ実行仕様書（設計セッションからの引き継ぎ）
```

> 注: `SKILL.md`・`references/`・`evaluation/` 配下の `goal.md`（eval出力）・`trigger-eval.json`
> などは、Claudeが読む動作定義／実際に生成・実行された記録として **英語のまま** 保持しています。

## 検証サマリー（と正直な注意点）

このスキルは書いただけでなく、計測しています:

- **出力品質** — 実際のfixtureに対しスキルあり／なしのランを実行。スキルは2イテレーション通じて
  **100%**（CI設定とpackage.jsonの食い違い・スコープ詐称・リポジトリ無しのケースを含む）。
  一方スキルなしのベースラインは、停止句・最新ターンのアンカー・ガードレールを毎回落とし、
  時には「do not stop until…（〜するまで止まるな）」という、まさにこのツールが防ぐべき暴走条件を書きました。
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
- **プローブ第2弾（フェーズ3）** — 停滞句・ガードレールの提示エビデンス・幻の証拠シグナル・
  時間上限・AND チェックリストの各分岐を再検証し、5点をすべて SKILL.md に反映（例:
  停滞句は単独文だと0/4、条件にOR結合すると4/4完了。時間上限は経過時間を毎ターン明示すれば
  4/4完了、無ければ0/4）。生ログは `evaluation/probes-2026-07/raw-log.md`、詳細は
  `references/evaluator-behavior-tests.md` を参照。
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
- **2026-07以降の全ランは、被験体モデル・実行日・スキル版（コミットハッシュ）を記録しています。**

正直な注意点: トリガー検証は実際の `available_skills` 発火機構の **近似** です。評価器の実験は
**再構成した** 評価器プロンプトと小さいサンプルサイズを用いています。iteration-2のベースラインの
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
