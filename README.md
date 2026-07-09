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
  iteration-2/              罠ケース    — スキルあり100% / なし約82%
  trigger-eval.json         20問のトリガー評価セット（近似ミス含む）
  desc-opt/trigger-results.md   トリガー精度の結果と原因分析メモ
```

> 注: `SKILL.md`・`references/`・`evaluation/` 配下の `goal.md`（eval出力）・`trigger-eval.json`
> などは、Claudeが読む動作定義／実際に生成・実行された記録として **英語のまま** 保持しています。

## 検証サマリー（と正直な注意点）

このスキルは書いただけでなく、計測しています:

- **出力品質** — 実際のfixtureに対しスキルあり／なしのランを実行。スキルは2イテレーション通じて
  **100%**（CI設定とpackage.jsonの食い違い・スコープ詐称・リポジトリ無しのケースを含む）。
  一方スキルなしのベースラインは、停止句・最新ターンのアンカー・ガードレールを毎回落とし、
  時には「do not stop until…（〜するまで止まるな）」という、まさにこのツールが防ぐべき暴走条件を書きました。
- **トリガー** — 3名の独立した判定者が、難しめの近似ミス（`/loop`、Stopフック、Agent SDK、OKR、
  単発実行）を含むセットで説明文を **20/20** と評価しました。

正直な注意点: トリガー検証は実際の `available_skills` 発火機構の **近似** です。評価器の実験は
**再構成した** 評価器プロンプトと小さいサンプルサイズを用いています。iteration-2のベースラインの
一部は条件が混入しています。数値は強い示唆であって保証ではありません。（公式の `skill-creator`
最適化ループはこの環境では数値を出せませんでした ── サブプロセスのパイプに対する `select.select()`
というWindows移植性バグのため。原因分析メモを参照。）

## 免責事項

Anthropic とは無関係で、公認もされていません。公開ドキュメントと作者自身の実験に基づいて構築しており、
`[inference]`／`[tested]` の部分は公式ではありません。[公式ドキュメント](https://code.claude.com/docs/en/goal)
で検証してください。両者が食い違う場合は公式が優先されます。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
