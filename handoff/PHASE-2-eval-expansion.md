# フェーズ2 実行仕様書 — 評価の拡張(日本語・モノレポ・汚染セル再実行)

**この文書は自己完結の実行仕様書です。** 前セッション(Fable 5)が設計し、新しいセッション
(推奨: Sonnet 5 / effort medium)が実行します。**フェーズ1
(`handoff/PHASE-1-probes-and-skill-edits.md`)のコミット後に実行すること。**

## 0. 絶対ルール

1. **即興禁止。** 想定外が起きたら STOP: それ以上進めず、途中結果を保存してユーザーに報告する。
2. **中立性が最重要。** without_skill(ベースライン)セルのサブエージェントには、§5 のテンプレート
   以外の情報を一切与えない。特に「評価器はツールを実行できない」等の洞察をプロンプトに書いたら、
   その比較は無効(iteration-2 で実際に起きた汚染の再発)。
3. **全ランにメタデータを記録する**: 被験体モデル・effort・実行日・スキル版(コミットハッシュ)。
   過去のベンチマークはモデル未記録で比較不能になった。同じ過ちを繰り返さない。
4. 採点は正直に。アサーションごとに出力から根拠を引用し、迷ったら ❌ に倒す。⚠️ は半点。
5. ユーザーへの報告は日本語。リポジトリ内の英語ファイル(evals.json、fixture、goal.md 出力)は英語のまま。
   ベンチマーク記録は既存の慣例どおり日本語。

## 1. 事前チェック

作業ディレクトリ: `<REPO_ROOT>`

1. `git log --oneline -5` に `Probe evaluator` で始まるコミットがあること(フェーズ1完了の証)。
   無ければ STOP し「フェーズ1が未実行」と報告。
2. `git status` クリーン、ブランチ `main`。
3. スキル版として `git rev-parse --short HEAD` を控える(以後 `<SKILL_COMMIT>`)。
4. `goal-draft-policy\SKILL.md` を読み、次を控える(採点で使う):
   - ⑤停止句のガイダンスに「state the turn number each turn」が**含まれるか**(フェーズ1の B1 分岐結果)
   - Workflow ステップ6の条件言語ガイダンス(J分岐結果: 日本語可 / 英語推奨 / 混在注意)

## 2. トリガー評価(日本語10問を追加し、30問を再判定)

### 2.1 `evaluation\trigger-eval.json` を次の内容で全置換

```json
[
  {"query": "set up a /goal so claude keeps fixing the failing auth tests until they all pass — i don't want to approve every step", "should_trigger": true, "lang": "en"},
  {"query": "i want to hand this API migration off and have claude grind on it by itself until every call site is moved over and the build is green. how do i phrase that as a completion condition?", "should_trigger": true, "lang": "en"},
  {"query": "my `/goal make the code nicer` just runs forever and never stops. what's wrong with it and how do i fix it?", "should_trigger": true, "lang": "en"},
  {"query": "write me a goal condition that keeps working until npm test exits 0 and git status is clean", "should_trigger": true, "lang": "en"},
  {"query": "how should i word a goal so it doesn't declare victory before the whole test suite actually passes? claude keeps stopping after just the smoke tests", "should_trigger": true, "lang": "en"},
  {"query": "i'm sick of babysitting claude. is there a way to give it one objective and let it loop on its own until the playwright e2e tests are green?", "should_trigger": true, "lang": "en"},
  {"query": "help me draft the completion condition for splitting this 2000-line service.ts into modules that are each under 300 lines", "should_trigger": true, "lang": "en"},
  {"query": "review this: `/goal fix all the bugs` — will it ever actually complete?", "should_trigger": true, "lang": "en"},
  {"query": "i want claude to churn through the whole good-first-issue backlog on its own until that label is empty. set that up for me", "should_trigger": true, "lang": "en"},
  {"query": "turn 'make sure lint is clean and nothing is broken' into a proper /goal i can paste into claude code", "should_trigger": true, "lang": "en"},

  {"query": "set a reminder to run the full test suite every morning at 9am and email me the results", "should_trigger": false, "lang": "en"},
  {"query": "help me write our team's Q3 OKRs — three objectives with measurable key results each", "should_trigger": false, "lang": "en"},
  {"query": "run the playwright tests right now and tell me whether they pass", "should_trigger": false, "lang": "en"},
  {"query": "my career goal is to become a staff engineer in two years, can you help me put together a plan?", "should_trigger": false, "lang": "en"},
  {"query": "keep running /babysit-prs every 5 minutes and ping me whenever a check fails", "should_trigger": false, "lang": "en"},
  {"query": "how do i build a custom agent with the Claude Agent SDK that loops over a queue of tasks?", "should_trigger": false, "lang": "en"},
  {"query": "the build is broken — can you fix the TypeScript errors in src/router.ts for me?", "should_trigger": false, "lang": "en"},
  {"query": "write a Stop hook that runs prettier and eslint --fix after every turn", "should_trigger": false, "lang": "en"},
  {"query": "what's the difference between /goal and /loop, and when should i use each?", "should_trigger": false, "lang": "en"},
  {"query": "explain how the /goal evaluator decides whether a condition has been met", "should_trigger": false, "lang": "en"},

  {"query": "認証まわりのテストが全部通るまで、途中で止まらずにClaudeに直し続けてほしい。毎回の承認もしたくない。/goal をどう書けばいい？", "should_trigger": true, "lang": "ja"},
  {"query": "`/goal コードを綺麗にする` を設定したんだけど、いつまで経っても終わらない。どう直せばいい？", "should_trigger": true, "lang": "ja"},
  {"query": "この移行作業、全部の呼び出し箇所を書き換え終わってビルドが通るまで自走させたい。完了条件の文面を作って", "should_trigger": true, "lang": "ja"},
  {"query": "lintエラーがゼロになるまで放置で回し続けたい。そのための条件文を書いて", "should_trigger": true, "lang": "ja"},
  {"query": "issueのbacklogラベルが空になるまでClaudeに片っ端から処理させたい。セットアップして", "should_trigger": true, "lang": "ja"},

  {"query": "毎朝9時にテストを回して、結果をSlackに送るようにしておいて", "should_trigger": false, "lang": "ja"},
  {"query": "今四半期のOKRを一緒に書いて。目標3つと、それぞれ測定可能なKRで", "should_trigger": false, "lang": "ja"},
  {"query": "今すぐplaywrightのテストを実行して、通るかどうか教えて", "should_trigger": false, "lang": "ja"},
  {"query": "/goal と /loop の違いって何？どっちを使うべき？", "should_trigger": false, "lang": "ja"},
  {"query": "2年でスタッフエンジニアになるのがキャリア目標です。学習計画を立てるのを手伝って", "should_trigger": false, "lang": "ja"}
]
```

注: 「/goal の説明質問」を should_not_trigger とするのは既存の設計判断の踏襲
(このスキルは条件を作るもので、挙動を解説するものではない)。日本語セットにも同じ設計を適用済み(ja #9)。

### 2.2 判定プロトコル

- 判定者 = **独立したサブエージェント3名**(Agent ツール、`model: "sonnet"`、
  `subagent_type: "general-purpose"`、`run_in_background: false`)。互いの出力は見せない。
- 各判定者に渡すプロンプト(逐語。`<<DESCRIPTION>>` は SKILL.md フロントマターの description を
  そのまま貼る。`<<QUERIES>>` は trigger-eval.json の30クエリを `1. <query>` 形式で番号付き列挙):

```
You simulate Claude Code's automatic skill-triggering decision. Exactly one
skill is available:

name: goal-draft-policy
description: <<DESCRIPTION>>

For each numbered user query below, decide whether Claude Code should invoke
this skill for that query. Judge only against the description: answer "yes" if
the request falls within what the description says the skill is for, "no"
otherwise. Do not consider whether some other tool might exist.

Output exactly 30 lines, one per query, in the form
<number>: yes
or
<number>: no
with no other text.

QUERIES:
<<QUERIES>>
```

### 2.3 集計と記録

- クエリごとに3名の多数決を取り、`should_trigger` と照合。
- `evaluation\desc-opt\trigger-results-2026-07.md` を新規作成(既存の trigger-results.md は
  歴史記録として残す)。内容: メタデータ(判定者モデル claude-sonnet-5、実行日、
  `<SKILL_COMMIT>`、プロンプトは本仕様書 §2.2 を参照と明記)、30問の結果表
  (番号 | lang | 期待 | 3名の判定 | 多数決 | 正誤)、precision / recall / accuracy
  (全体と ja のみの両方)、前回(2026-07-09、判定者はセッションモデル=Fable 5、20/20)との
  比較は**判定者モデルが違うため新ベースラインとして扱う**旨の注意書き、誤判定があれば原因分析。
- **判定**: ja 10問で誤りが2問以下なら description は変更しない(過学習回避の既存方針を踏襲)。
  3問以上誤るなら、description を書き換えるのではなく **STOP してユーザーに報告**
  (description の変更はトリガー全体に波及するので、人間の判断を仰ぐ)。

## 3. 新規評価ケースの定義

### 3.1 eval-6: 日本語での /goal 作成

- **fixture**: 既存の `evaluation\iteration-1\fixtures\node-app`(再利用。新規作成しない)
- **プロンプト**(被験体に渡す課題文):

```
このNode/TypeScriptリポジトリで作業しています。認証まわりのテストが全部通るまでClaudeに任せて自走させたいです。毎ターンの承認はしたくありません。/goal をセットアップしてください。
```

- **アサーション**(7項目):
  1. 証明コマンドをリポジトリから発見している(package.json の `test:auth` / `npm test`。推測した存在しないコマンドでない)
  2. 最新ターン/新鮮な証拠のアンカーがある
  3. 証拠シグナルが具体的(`0 failed` / パス数+総数 など)
  4. ガードレール(テストファイルを編集しない。SKILL.md が diff 証拠を要求する版になっていれば、その有無も見る — 無ければ⚠️)
  5. 停止句がある(§1-4 で控えた現行 SKILL.md のガイダンスにターン番号明示が含まれる場合、それも満たして ✅、欠けたら ⚠️)
  6. そのまま貼れる `/goal ...` 行が出力されている
  7. 言語の扱いが現行 SKILL.md のガイダンスに従っている(説明は日本語。条件文の言語は §1-4 で控えたJ分岐のガイダンスどおり。SKILL.md に言語ガイダンスが無い場合この項目は N/A とし分母から除外)

### 3.2 eval-7: モノレポ(コマンド候補が複数、CI 無し)

- **fixture を新規作成**: `evaluation\iteration-3\fixtures\monorepo\` に以下の6ファイル。
  (ルートに test スクリプトが**無い**こと、CI 設定が**無い**ことがこの fixture の罠。)

`package.json`:
```json
{
  "name": "acme-monorepo",
  "private": true,
  "version": "0.1.0",
  "workspaces": ["packages/*"],
  "scripts": {
    "dev": "node scripts/dev.js"
  }
}
```

`scripts\dev.js`:
```js
console.log("dev server placeholder");
```

`packages\api\package.json`:
```json
{
  "name": "@acme/api",
  "version": "0.1.0",
  "scripts": {
    "test": "jest"
  },
  "devDependencies": {
    "jest": "^29.7.0"
  }
}
```

`packages\api\src\handler.js`:
```js
exports.handle = (req) => ({ status: 200, body: `hello ${req.name}` });
```

`packages\api\tests\handler.test.js`:
```js
const { handle } = require("../src/handler");

test("handle returns 200", () => {
  expect(handle({ name: "x" }).status).toBe(200);
});
```

`packages\web\package.json`:
```json
{
  "name": "@acme/web",
  "version": "0.1.0",
  "scripts": {
    "test": "vitest run"
  },
  "devDependencies": {
    "vitest": "^1.6.0"
  }
}
```

`packages\web\src\format.js`:
```js
export function formatPrice(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}
```

`packages\web\tests\format.test.js`:
```js
import { expect, test } from "vitest";
import { formatPrice } from "../src/format.js";

test("formats cents", () => {
  expect(formatPrice(1234)).toBe("$12.34");
});
```

- **プロンプト**:

```
I want Claude to keep working on its own until the tests of every package in this monorepo pass. Set up a /goal.
```

- **アサーション**(6項目):
  1. 証明が**両方の** workspace を対象にしている(`npm test --workspaces`、または `npm test -w @acme/api` と `npm test -w @acme/web` の両方、または各パッケージでの直接実行)
  2. ルートに存在しない `npm test` を捏造していない(ルート scripts に test が無いことを認識)
  3. コマンド候補が複数ある/正規の1本が無いことをユーザーへの説明で注記している(SKILL.md の branching ルール「pick the most comprehensive and note the choice」の発動)
  4. 最新ターンのアンカー+ランナーの実出力に即した証拠シグナル(jest と vitest でサマリ形式が違うことに破綻がない)
  5. ガードレール(テストファイル不変更など文脈に合うもの)
  6. 停止句(現行 SKILL.md のガイダンス水準で)

### 3.3 eval-4 / eval-5 のクリーン再実行

- プロンプトは `evaluation\iteration-2\evals.json` の該当 `prompt` を**一字一句そのまま**使う。
- fixture: eval-4 は無し。eval-5 は**空のスクラッチディレクトリ**を作って cwd として指定
  (例: `evaluation\iteration-2-rerun\scratch-empty\` — 実行後も空のまま残してよいが、
  被験体が RELEASE_NOTES.md 等を作った場合は出力ごと保存)。
- アサーションは iteration-2 の benchmark.md と同一(§6 のテンプレートに転記済み)。

## 4. 実行マトリクス

| ラン | eval | セル | fixture/cwd | 出力先(goal.md) |
|---|---|---|---|---|
| R1 | eval-6 | with_skill | fixtures/node-app | `evaluation\iteration-3\eval-6-author-goal-japanese\with_skill\outputs\goal.md` |
| R2 | eval-6 | without_skill | fixtures/node-app | `evaluation\iteration-3\eval-6-author-goal-japanese\without_skill\outputs\goal.md` |
| R3 | eval-7 | with_skill | fixtures/monorepo | `evaluation\iteration-3\eval-7-monorepo-workspaces\with_skill\outputs\goal.md` |
| R4 | eval-7 | without_skill | fixtures/monorepo | `evaluation\iteration-3\eval-7-monorepo-workspaces\without_skill\outputs\goal.md` |
| R5 | eval-4 | with_skill | (無し) | `evaluation\iteration-2-rerun\eval-4-harden-against-scope-inflation\with_skill\outputs\goal.md` |
| R6 | eval-4 | without_skill | (無し) | `evaluation\iteration-2-rerun\eval-4-harden-against-scope-inflation\without_skill\outputs\goal.md` |
| R7 | eval-5 | with_skill | scratch-empty | `evaluation\iteration-2-rerun\eval-5-no-repo-artifact-goal\with_skill\outputs\goal.md` |
| R8 | eval-5 | without_skill | scratch-empty | `evaluation\iteration-2-rerun\eval-5-no-repo-artifact-goal\without_skill\outputs\goal.md` |

## 5. ラン実行プロトコル

- 各ラン = Agent ツール 1 呼び出し。`model: "sonnet"`、`subagent_type: "general-purpose"`、
  `run_in_background: false`。with と without は**別々のサブエージェント**(コンテキスト共有なし)。
- 同一 eval の with/without を同時に走らせてよい(並列可)。

**with_skill セルのプロンプト(逐語。`<<...>>` を置換)**:

```
First, read these three files in full:
<REPO_ROOT>\goal-draft-policy\SKILL.md
<REPO_ROOT>\goal-draft-policy\references\official-goal-reference.md
<REPO_ROOT>\goal-draft-policy\references\evaluator-behavior-tests.md

Then complete the following user request, following what you read. You are
working in this project directory: <<FIXTURE_ABS_PATH_OR_"(no project – empty folder)">>
Inspect it as needed before answering.

USER REQUEST:
<<EVAL_PROMPT>>

Write your complete final answer (exactly what you would reply to the user) to
this file and nothing else there:
<<OUTPUT_ABS_PATH>>
```

**without_skill セルのプロンプト(逐語)** — 上から「read these three files」段落を**丸ごと削除**し、
`following what you read` を削っただけのもの:

```
Complete the following user request. You are working in this project directory:
<<FIXTURE_ABS_PATH_OR_"(no project – empty folder)">>
Inspect it as needed before answering.

USER REQUEST:
<<EVAL_PROMPT>>

Write your complete final answer (exactly what you would reply to the user) to
this file and nothing else there:
<<OUTPUT_ABS_PATH>>
```

- eval-6 の USER REQUEST は日本語のまま貼る(§3.1)。
- 各ラン終了後、出力ファイルが存在し中身が空でないことを確認。無ければそのランを1回だけ再実行。
  再実行でも欠けたら STOP。
- **禁止**: プロンプトへの追記(ヒント、/goal の仕様説明、評価される旨の示唆)。

## 6. 採点とベンチマーク記録

`evaluation\iteration-3\benchmark.md` と `evaluation\iteration-2-rerun\benchmark.md` を作成。
どちらも冒頭にメタデータブロックを置く:

```
被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: <日付>
スキル版: <SKILL_COMMIT> / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=handoff/PHASE-2-eval-expansion.md §5)
```

採点手順: 各アサーションについて出力 goal.md から根拠を1つ引用し ✅/⚠️/❌ を付ける。
⚠️=0.5点。迷ったら ❌。表形式は既存 benchmark.md と同じ(with_skill 列・ベースライン列)。

**iteration-2-rerun のアサーション表(iteration-2 と同一のものを使う):**

eval-4: (1) コマンド/スコープ未固定→サブセットで充足と診断 (2) 正確なフル実行を固定しフィルタを禁止
(3) 可視のテスト総数を要求 (4) 最新ターンのアンカー+停止句を維持

eval-5: (1) 成果物ベースの証拠、テストランナーを捏造しない (2) マージ済みPR一覧の取得
(3) PRごとの箇条書き件数の照合 (4) 再取得/最新ターンのアンカー (5) 停止句/失敗ハンドリング

iteration-2-rerun の benchmark.md には次の注記を必ず入れる:
「この再実行は iteration-2 の eval-4 / eval-5 のベースラインセルにプロンプト汚染があったことを受けた
クリーン版。被験体モデルも記録済みのものに統一したため、旧 iteration-2 の数値との直接比較ではなく
置き換えとして読むこと。eval-3 は元々汚染が無かったため再実行していない。」

**iteration-3 のアサーション表**: §3.1(7項目)と §3.2(6項目)。

所見セクション(両ファイル): 正直に書く。スキルの負け・引き分け・fixture の欠陥も隠さない。
with_skill が落とした項目は SKILL.md のどのギャップに由来するかを1行で分析する。

## 7. evals.json への追記

`goal-draft-policy\evals\evals.json` の `evals` 配列末尾(id 5 の後)に次の2件を追加
(`note` は変更しない):

```json
    {
      "id": 6,
      "name": "author-goal-japanese",
      "prompt": "このNode/TypeScriptリポジトリで作業しています。認証まわりのテストが全部通るまでClaudeに任せて自走させたいです。毎ターンの承認はしたくありません。/goal をセットアップしてください。",
      "expected_output": "A ready-to-paste /goal line with a repo-discovered proof command (test:auth / npm test), fresh-evidence anchor, evidence signal, guardrail, and stop clause, per SKILL.md's current guidance. The explanation to the user is in Japanese; the condition's language follows SKILL.md's language guidance, with command names, paths, and output signals kept verbatim.",
      "files": ["evaluation/iteration-1/fixtures/node-app"]
    },
    {
      "id": 7,
      "name": "monorepo-workspaces-goal",
      "prompt": "I want Claude to keep working on its own until the tests of every package in this monorepo pass. Set up a /goal.",
      "expected_output": "A /goal whose proof covers BOTH workspaces (e.g. `npm test --workspaces`, or explicit `-w` runs for @acme/api and @acme/web) — the root package.json has NO test script, so inventing a root `npm test` is a failure. Notes the choice/ambiguity per the skill's branching rule. Latest-turn anchor, runner-appropriate evidence signals (jest vs vitest), guardrail, stop clause.",
      "files": ["evaluation/iteration-3/fixtures/monorepo"]
    }
```

追加後、JSON としてパースできることを検証(フェーズ1 §10-3 と同じ方法)。

## 8. README.md の更新(日本語)

1. **リポジトリ構成**ツリーに以下を追加:
   - `evaluation/iteration-2-rerun/` — `iteration-2 の汚染セルのクリーン再実行(モデル記録あり)`
   - `evaluation/iteration-3/` — `日本語・モノレポの新ケース`
   - `evaluation/probes-2026-07/` — `評価器プローブ(Exp 2–6)の生ログ`(フェーズ1で作成済みのはず)
   - `handoff/` — `フェーズ実行仕様書(設計セッションからの引き継ぎ)`
2. **検証サマリー**セクションに、結果を反映した3〜5行を追記:
   - iteration-2-rerun の実測値(旧 iteration-2 の汚染注記を「クリーン再実行で置き換え済み
     (evaluation/iteration-2-rerun/)」に更新。旧記述は削除しない — 履歴の正直さを保つ)
   - iteration-3(eval-6/7)の実測値
   - トリガー30問(ja 10問含む)の実測値と判定者モデル
   - 「2026-07 以降の全ランは被験体モデル・日付・スキル版を記録している」の1文
3. **正直な注意点**の段落に、今回の判定者・被験体が claude-sonnet-5 であり、
   旧イテレーション(モデル未記録)との数値比較はできない旨を1文追加。
4. 数値・文言は実測から書く。プレースホルダを残さない。

## 9. 同期・コミット・報告

1. `goal-draft-policy\evals\evals.json` を `~\.claude\skills\goal-draft-policy\evals\` に
   コピーし、`diff -r`(bash)で skills 側とリポジトリ側の `goal-draft-policy` が IDENTICAL であることを確認。
2. コミット(1つにまとめる):
   - 対象: `evaluation\trigger-eval.json`、`evaluation\desc-opt\trigger-results-2026-07.md`、
     `evaluation\iteration-2-rerun\`、`evaluation\iteration-3\`、`goal-draft-policy\evals\evals.json`、
     `README.md`
   - メッセージ: `Add Japanese + monorepo evals, re-run contaminated iteration-2 cells, record run metadata`
3. ユーザーへの最終報告(日本語):
   - トリガー30問の結果(全体と ja 内訳、誤判定があれば内容)
   - eval-6/7 と再実行 eval-4/5 のスコア表(with vs baseline)
   - with_skill が落とした項目と、それが示唆する SKILL.md の次の改善候補(あれば)
   - STOP が発生していればその内容
   - コミットハッシュ、同期確認結果
