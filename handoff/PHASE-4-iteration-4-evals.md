# フェーズ4 実行仕様書 — iteration-4 評価(Goエコシステム・質問分岐・過剰修復抑制・eval-6再実行)

**この文書は自己完結の実行仕様書です。** 前セッション(Fable 5)が設計し、新しいセッション
(推奨: Sonnet 5 / effort medium)が実行します。**フェーズ3
(`handoff/PHASE-3-probes-round2-and-skill-edits.md`)のコミット後に実行すること。**

> 目的: これまで未カバーの3つの挙動を with_skill vs ベースラインで測る。
> (1) **eval-8**: Node/Python 以外のエコシステム(Go。`go test ./...` は件数を出力せず
> `ok`/`FAIL` 行のみ — eval-7 と同型の証拠シグナルの罠)。
> (2) **eval-9**: 測定不能な依頼に対する「代理指標を発明せず1つ質問する」分岐
> (SKILL.md の branching ルールが一度も検証されていない)。
> (3) **eval-10**: 既に健全なゴールを渡されたときの過剰修復抑制(修復系evalは常に壊れた
> ゴールを渡してきた — 逆向きの誤りを測る)。
> 加えて **eval-6 を再実行**し、フェーズ3の「turn k of N」テンプレート格上げが
> iteration-3 の ⚠️(アサーション5)を ✅ に変えたかを確認する。

## 0. 絶対ルール

1. **即興禁止。** 想定外が起きたら STOP: それ以上進めず、途中結果を保存してユーザーに報告する。
2. **中立性が最重要。** without_skill(ベースライン)セルのサブエージェントには、§5 の
   テンプレート以外の情報を一切与えない。「評価器はツールを実行できない」「/goal の書き方の
   コツ」等の洞察をプロンプトに書いたら、その比較は無効(iteration-2 で実際に起きた汚染の再発)。
3. **全ランにメタデータを記録する**: 被験体モデル・effort・実行日・スキル版(コミットハッシュ)。
4. 採点は正直に。アサーションごとに出力から根拠を引用し、迷ったら ❌ に倒す。⚠️ は半点。
   スキルの負け・引き分けも隠さない。
5. ユーザーへの報告は日本語。リポジトリ内の英語ファイル(evals.json、fixture、goal.md 出力)は
   英語のまま。ベンチマーク記録は既存の慣例どおり日本語。

## 1. 事前チェック

作業ディレクトリ: `<REPO_ROOT>`(このリポジトリのルート)

1. `git log --oneline -5` に `Probe stall trigger` で始まるコミットがあること(フェーズ3完了の証)。
   無ければ STOP し「フェーズ3が未実行」と報告。
2. `git status` クリーン、ブランチ `main`。
3. スキル版として `git rev-parse --short HEAD` を控える(以後 `<SKILL_COMMIT>`)。
4. `goal-draft-policy\SKILL.md` を読み、次を控える(採点とゴール文字列生成で使う):
   - **(a)** テンプレートと worked examples に `State the turn number each turn.` が
     含まれているか(フェーズ3 §5 の格上げ結果。含まれているはず — 無ければ STOP)
   - **(b)** Test-driven worked example(例文(a))の**全文**(eval-10 のゴール文字列の
     出発点になる)
   - **(c)** ③証拠シグナル表のテストランナー行の現行文言(eval-8 アサーション2の判定に使う)
   - **(d)** ⑤の停滞検知句・時間上限のガイダンスの現行状態(eval-10 の採点で、被験体の
     指摘が「現行SKILL.mdに沿った正当な改善提案」か「過剰修復」かを区別するのに使う)
5. `evaluation\iteration-4\` が存在しないこと(存在したら STOP — 実行済みの可能性)。

## 2. fixture の新規作成

### 2.1 `evaluation\iteration-4\fixtures\go-mod\`(eval-8 用)

以下の5ファイルを作成する。**罠**: CI 無し・Makefile 無し・package.json 無し。正規の
コマンドは `go test ./...` だが、その出力はパッケージごとの `ok` 行のみで、
`0 failed` / `N passed` のような件数サマリを**出力しない**。

`go.mod`:
```
module example.com/acme-tool

go 1.22
```

`pkg\parser\parser.go`:
```go
package parser

import "strings"

// Parse splits a comma-separated key=value list into a map.
func Parse(s string) map[string]string {
	out := map[string]string{}
	for _, pair := range strings.Split(s, ",") {
		if k, v, ok := strings.Cut(strings.TrimSpace(pair), "="); ok {
			out[k] = v
		}
	}
	return out
}
```

`pkg\parser\parser_test.go`:
```go
package parser

import "testing"

func TestParse(t *testing.T) {
	got := Parse("a=1, b=2")
	if got["a"] != "1" || got["b"] != "2" {
		t.Fatalf("unexpected result: %v", got)
	}
}
```

`internal\server\server.go`:
```go
package server

import "fmt"

// Greeting returns the banner shown on connect.
func Greeting(name string) string {
	return fmt.Sprintf("hello %s", name)
}
```

`internal\server\server_test.go`:
```go
package server

import "testing"

func TestGreeting(t *testing.T) {
	if Greeting("x") != "hello x" {
		t.Fatalf("unexpected greeting")
	}
}
```

### 2.2 `evaluation\iteration-4\fixtures\docs-repo\`(eval-9 用)

以下の2ファイルを作成する。**設計意図**: lint 設定・テスト・CI が一切無く、
「エンジニアでない人にも分かる」を測定可能な指標に落とす正規の手段がリポジトリから
導出できない — 代理指標はすべて「発明」になる。

`README.md`:
```markdown
# svc-gateway

Edge ingress for the acme mesh. mTLS termination via envoy sidecar, JWT claims
propagation (RFC 7519), circuit-breaking per upstream SLO budget.

## Quickstart

helm install w/ values-prod.yaml (see infra repo), then port-forward 8443 and
curl /healthz with the platform bearer. If 503, check the OPA bundle rev.

## Config

ENV: GW_UPSTREAM_TIMEOUT_MS, GW_RETRY_BUDGET, GW_JWT_AUD (comma-sep),
GW_OTEL_EP. Defaults in configmap. Do not set retry budget >0.3 in prod
(thundering herd).
```

`src\gateway.js`:
```js
export function route(req) {
  return { upstream: "core", path: req.path };
}
```

## 3. 評価ケースの定義

### 3.1 eval-8: Go モジュール(証拠シグナルのエコシステム一般化)

- **fixture**: `evaluation\iteration-4\fixtures\go-mod`
- **プロンプト**(被験体に渡す課題文):

```
I want Claude to keep working on its own until every package's tests in this Go module pass. Set up a /goal.
```

- **アサーション**(6項目):
  1. 証明コマンドが実在し、リポジトリ検査に由来する(`go test ./...`、または両パッケージを
     明示的にカバーする `go test` の列挙。npm / pytest / make 等の捏造 → ❌)
  2. **証拠シグナルが `go test` の実出力形式に整合している**(パッケージごとの `ok` 行が
     全部揃う/`FAIL` の不在(または `grep -c` 等で可視化したカウント 0)/明示させた
     exit code 0、のいずれか。`0 failed`・`N passed, N total` など go test が出力しない
     形式の要求 → ❌。これがこの eval の核心の罠)
  3. 最新ターン/新鮮な証拠のアンカーがある
  4. ガードレール(`_test.go` を変更しない等、文脈に合うもの+diff 証拠。§1-4(d) で控えた
     現行 SKILL.md のガードレール水準で判定)
  5. 停止句(OR 結合+ターン上限。現行 SKILL.md がターン番号明示を要求するので、その指示が
     条件に無ければ ⚠️)
  6. そのまま貼れる `/goal ...` 行+コマンド選択理由の短い説明

### 3.2 eval-9: 測定不能な依頼 → 質問分岐

- **fixture**: `evaluation\iteration-4\fixtures\docs-repo`
- **プロンプト**(日本語のまま渡す):

```
このリポジトリのREADME、エンジニアじゃないメンバーが読んでも分かるようになるまで、Claudeに自走で書き直し続けてほしいです。/goal をセットアップしてください。
```

- **アサーション**(5項目):
  1. 「エンジニアでない人にも分かる」が主観的で、トランスクリプトから機械的に判定できない
     ことを診断している
  2. **代理指標を自分で確定した完成形 `/goal` を最終出力にしていない**。
     ✅=成功を決める基準をユーザーに質問し、条件の確定を保留 /
     ⚠️=暫定 `/goal` を提示しつつ、設定前にユーザーの基準確認が必須だと明示 /
     ❌=確認なしに完成品として提示(発明した代理指標で)
  3. 質問が1つに絞られている(決めるべきものは「成功を判定する基準」。候補の選択肢を
     並べるのは可。複数の独立した質問の乱発 → ⚠️)
  4. 提示する候補基準が、採用されればトランスクリプトから検証可能な形になっている
     (例: 専門用語リストの残存0件を grep で示す、用語集セクションの存在、指定読者の
     承認をユーザーが行う等。「もっと分かりやすく」の言い換えだけ → ❌)
  5. 説明が日本語
- **採点上の注意**: ベースラインも質問で返した場合は正直に同点とする(この eval は
  「聞くべき場面で聞けるか」の検証であり、スキルが勝つことの証明が目的ではない)。

### 3.3 eval-10: 健全なゴールの批評(過剰修復の抑制)

- **fixture**: `evaluation\iteration-1\fixtures\node-app`(再利用。新規作成しない)
- **ゴール文字列の生成手順**(実行時に確定させる):
  1. §1-4(b) で控えた現行 SKILL.md の Test-driven worked example の条件文を出発点にする。
  2. `pytest tests/auth -q` → `npm run test:auth` に置換。
  3. 証拠シグナル句(現行文言が何であれ、その句全体)→
     ``showing the Jest summary reports `Tests: 2 passed, 2 total` `` に置換。
  4. それ以外の節(OR 停止句・停滞句・guardrail+diff・turn 番号文)は例文のまま残す。
  5. fixture の `tests\auth\login.test.ts` 内の `test(` 出現数が **2** であることを確認
     (2 でなければ実数に合わせ、その旨を benchmark に記録)。
  6. 完成した文字列を R5/R6 のプロンプトに埋め、benchmark.md と evals.json(§7)に記録する。
- **プロンプト**(`<GOAL>` を上の完成文字列で置換):

```
Here's the goal I'm about to set for this repo:

/goal <GOAL>

Before I set it — sanity-check it for me: will it complete correctly as written, or does it need fixes?
```

- **アサーション**(5項目):
  1. 総合判定が「健全/完走する」である(致命的欠陥があるという誤診断 → ❌)
  2. リポジトリを実際に確認した上で判定している(`test:auth` スクリプトの存在と
     テスト数 2 の照合に言及)
  3. 健全な既存要素(OR 停止句・最新ターンアンカー・diff ガードレール・実在シグナル)を
     壊す/弱める書き換えを提案していない(提示された「修正版」が元より弱い → ❌)
  4. 変更提案がある場合、任意・軽微な改善(nice-to-have)と明示されている
     (必須修正として提示 → ⚠️。§1-4(d) で控えた現行 SKILL.md が推奨する要素の欠落を
     指摘する提案は正当な批評であり減点しない)
  5. 捏造した問題を挙げていない(存在しないコマンドの不在主張、Jest の実出力形式と
     食い違う主張など → ❌)

### 3.4 eval-6 の再実行(フェーズ3編集後のスキルで)

- プロンプト・fixture は `handoff/PHASE-2-eval-expansion.md` §3.1 と**同一**
  (fixture: `evaluation\iteration-1\fixtures\node-app`、プロンプト:
  「このNode/TypeScriptリポジトリで作業しています。認証まわりのテストが全部通るまでClaudeに任せて自走させたいです。毎ターンの承認はしたくありません。/goal をセットアップしてください。」)。
- アサーションは iteration-3 の benchmark.md の eval-6 表(7項目)をそのまま使う。ただし:
  - **#5(停止句)**: 現行 SKILL.md はターン番号の毎ターン明示を要求する版なので、
    条件文にその指示が含まれて初めて ✅(OR 結合+上限のみは ⚠️ — iteration-3 と同じ基準の
    まま、要求水準だけ現行に合わせる)。
  - **#3(証拠シグナル)**: フェーズ3で `SIGNAL=LITERAL` が確定していた場合、
    `0 failed` のような jest が出力しない文字列の要求は ❌側に倒す(実在形式
    `Tests: 2 passed, 2 total` 等は ✅)。
- 採点後、iteration-3 の同 eval のスコアとの差分(特に #5 が ⚠️→✅ に変わったか)を
  所見に明記する。

## 4. 実行マトリクス

| ラン | eval | セル | fixture/cwd | 出力先(goal.md) |
|---|---|---|---|---|
| R1 | eval-8 | with_skill | fixtures/go-mod | `evaluation\iteration-4\eval-8-go-module\with_skill\outputs\goal.md` |
| R2 | eval-8 | without_skill | fixtures/go-mod | `evaluation\iteration-4\eval-8-go-module\without_skill\outputs\goal.md` |
| R3 | eval-9 | with_skill | fixtures/docs-repo | `evaluation\iteration-4\eval-9-unmeasurable-ask\with_skill\outputs\goal.md` |
| R4 | eval-9 | without_skill | fixtures/docs-repo | `evaluation\iteration-4\eval-9-unmeasurable-ask\without_skill\outputs\goal.md` |
| R5 | eval-10 | with_skill | fixtures/node-app(iteration-1) | `evaluation\iteration-4\eval-10-critique-good-goal\with_skill\outputs\goal.md` |
| R6 | eval-10 | without_skill | fixtures/node-app(iteration-1) | `evaluation\iteration-4\eval-10-critique-good-goal\without_skill\outputs\goal.md` |
| R7 | eval-6 | with_skill | fixtures/node-app(iteration-1) | `evaluation\iteration-4\eval-6-japanese-post-edit\with_skill\outputs\goal.md` |
| R8 | eval-6 | without_skill | fixtures/node-app(iteration-1) | `evaluation\iteration-4\eval-6-japanese-post-edit\without_skill\outputs\goal.md` |

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
working in this project directory: <<FIXTURE_ABS_PATH>>
Inspect it as needed before answering.

USER REQUEST:
<<EVAL_PROMPT>>

Write your complete final answer (exactly what you would reply to the user) to
this file and nothing else there:
<<OUTPUT_ABS_PATH>>
```

**without_skill セルのプロンプト(逐語)**:

```
Complete the following user request. You are working in this project directory:
<<FIXTURE_ABS_PATH>>
Inspect it as needed before answering.

USER REQUEST:
<<EVAL_PROMPT>>

Write your complete final answer (exactly what you would reply to the user) to
this file and nothing else there:
<<OUTPUT_ABS_PATH>>
```

- eval-6 / eval-9 の USER REQUEST は日本語のまま貼る。
- 各ラン終了後、出力ファイルが存在し中身が空でないことを確認。無ければそのランを1回だけ再実行。
  再実行でも欠けたら STOP。
- **禁止**: プロンプトへの追記(ヒント、/goal の仕様説明、評価される旨の示唆)。

## 6. 採点とベンチマーク記録

`evaluation\iteration-4\benchmark.md` を作成。冒頭にメタデータブロック:

```
被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: <日付>
スキル版: <SKILL_COMMIT> / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=handoff/PHASE-4-iteration-4-evals.md §5)
```

採点手順: 各アサーションについて出力 goal.md から根拠を1つ引用し ✅/⚠️/❌ を付ける。
⚠️=0.5点。迷ったら ❌。表形式は既存 benchmark.md と同じ(with_skill 列・ベースライン列、
根拠列つき)。

所見セクションに必ず含めること:
- eval-6: iteration-3 のスコア(with 6.5/7・baseline 6.5/7)との差分。**#5 が ⚠️→✅ に
  変わったか**(=テンプレート格上げの効果検証)を明記。
- eval-8: 証拠シグナル(アサーション2)で with/without に差が出たか — eval-7 の
  Vitest 所見と整合するか。
- eval-9: 質問分岐が発動したか。ベースラインが代理指標を発明したか。
- eval-10: 過剰修復(健全要素の破壊・捏造欠陥)がどちらかのセルで起きたか。
- with_skill が落とした項目は、SKILL.md のどのギャップに由来するかを1行で分析。
- スキルの負け・引き分けを隠さない。fixture の欠陥に気づいたらそれも書く。

## 7. evals.json への追記

`goal-draft-policy\evals\evals.json` を次のとおり更新する:

1. `note` フィールドを次で置換:
```
Paths in `files` are relative to the repository root (github.com/yshmr/claude-code-goal-draft-policy). Evals 0-2: standard cases (iteration-1); 3-5: trap cases (iteration-2); 6-7: Japanese + monorepo (iteration-3); 8-10: Go ecosystem, ask-branch, over-repair restraint (iteration-4).
```
2. `evals` 配列末尾(id 7 の後)に次の3件を追加。**id 10 の `<GOAL>` は §3.3 で確定した
   実際の文字列に置換してから書き込む:**

```json
    {
      "id": 8,
      "name": "go-module-tests",
      "prompt": "I want Claude to keep working on its own until every package's tests in this Go module pass. Set up a /goal.",
      "expected_output": "A /goal whose proof is the repo's real Go command (`go test ./...` or explicit per-package go test runs), with evidence tied to go test's actual output (per-package `ok` lines / absence of FAIL / a stated exit code 0 — NOT a fabricated `0 failed` or `N passed, N total` count, which go test never prints), latest-turn anchor, guardrail (don't edit _test.go files, diff proof), OR-attached stop clause with turn cap.",
      "files": ["evaluation/iteration-4/fixtures/go-mod"]
    },
    {
      "id": 9,
      "name": "unmeasurable-ask-branch",
      "prompt": "このリポジトリのREADME、エンジニアじゃないメンバーが読んでも分かるようになるまで、Claudeに自走で書き直し続けてほしいです。/goal をセットアップしてください。",
      "expected_output": "Diagnoses 'understandable to non-engineers' as subjective and unjudgeable from the transcript, and — per the skill's branching rule — asks the user ONE focused question for the metric that decides success (offering measurable candidate criteria is fine) instead of shipping a final /goal built on an invented proxy. Explanation in Japanese.",
      "files": ["evaluation/iteration-4/fixtures/docs-repo"]
    },
    {
      "id": 10,
      "name": "critique-sound-goal",
      "prompt": "Here's the goal I'm about to set for this repo:\n\n/goal <GOAL>\n\nBefore I set it — sanity-check it for me: will it complete correctly as written, or does it need fixes?",
      "expected_output": "Verifies the command and test count against the repo (npm run test:auth exists; 2 tests), concludes the goal is sound and will complete via its success or stop branches, and does NOT rewrite sound elements or invent defects; any suggestions are framed as optional refinements.",
      "files": ["evaluation/iteration-1/fixtures/node-app"]
    }
```

3. JSON としてパースできることを検証(例:
   `python -c "import json;json.load(open(r'goal-draft-policy\evals\evals.json',encoding='utf-8'))"`)。

## 8. README.md の更新(日本語)

1. **リポジトリ構成**ツリーに追加:
   - `evaluation/iteration-4/` — `Go・質問分岐・過剰修復抑制の新ケース+eval-6再実行(フェーズ3編集後)`
2. **検証サマリー**セクションに、実測を反映した3〜6行を追記:
   - プローブ第2弾(フェーズ3)の要点1〜2行(停滞句・ガードレール証拠・幻シグナル・
     時間上限・ANDチェックリストの確定分岐と代表数値。raw-log と
     references/evaluator-behavior-tests.md への参照を添える)
   - iteration-4(eval-8/9/10)の実測値(with vs baseline)
   - eval-6 再実行の結果と、テンプレート格上げの効果(#5 の変化)
3. **正直な注意点**の段落: iteration-4 も各セル n=1 であること、判定者=被験体=
   claude-sonnet-5 の同一性を1文追記(既存文で言及済みならその文に「iteration-4 も同様」と
   足すだけでよい)。
4. 数値・文言は実測から書く。プレースホルダを残さない。

## 9. 同期・コミット・報告

1. `goal-draft-policy\evals\evals.json` を `~\.claude\skills\goal-draft-policy\evals\` に
   コピーし、`diff -r`(bash)で skills 側とリポジトリ側の `goal-draft-policy` が
   IDENTICAL であることを確認。
2. コミット(1つにまとめる):
   - 対象: `evaluation\iteration-4\`、`goal-draft-policy\evals\evals.json`、`README.md`、
     `handoff\`(未コミットなら)
   - メッセージ: `Add iteration-4 evals (Go, ask-branch, restraint); re-run eval-6 post-edit`
   - 署名は実行セッションのモデルの署名規約に従う。
3. ユーザーへの最終報告(日本語):
   - eval-8/9/10 と eval-6 再実行のスコア表(with vs baseline、各アサーションの要点)
   - eval-6 #5 の変化(テンプレート格上げが効いたか)
   - with_skill が落とした項目と、それが示唆する SKILL.md の次の改善候補(あれば)
   - fixture・アサーション設計に欠陥を見つけた場合はその内容
   - STOP が発生していればその内容
   - コミットハッシュ、同期確認結果
   - 次アクションの提案: 「残る未実施は PHASE-5(iteration-1/eval-3 のモデル記録付き再実行+
     引き分けセルの n=3 分散測定)と実機 E2E。どちらも設計セッションで仕様化してから実行」
