# フェーズ5 実行仕様書 — 質問分岐の強化+eval-9 再実行(n=3)+evals 0–3 のモデル記録付き再実行

**この文書は自己完結の実行仕様書です。** 前セッション(Fable 5)が設計し、新しいセッション
(推奨: Sonnet 5 / effort medium)が実行します。**フェーズ4
(`handoff/PHASE-4-iteration-4-evals.md`)のコミット後に実行すること。**

> 目的:
> (1) iteration-4 eval-9 で見つかったスキルの欠陥を修正する — with_skill エージェントが
> 「測定不能なら質問し、代理指標を発明しない」という分岐ルールに従わず、自分で決めた
> 代理指標で完成形 `/goal` を出してしまった。原因はルールの文言(「ask … then continue」)が
> 一括回答の文脈で「質問しつつ答えも出す」に流れる余地を残すこと、および worked trace の
> 「confirm/assume a budget」が assume を正当化して見えること。文言を「質問だけを返す」
> 停止指示に強化する。
> (2) 修正後の eval-9 を **各セル n=3** で再実行し、修正の効果を1回の分散と切り分けて測る。
> (3) README の看板数値(iteration-1: スキルなし58%)がモデル未記録の旧ランに依存している
> 問題を解消するため、evals 0–3 を記録付きプロトコルで再実行し新ベースラインを作る。

## 0. 絶対ルール

1. **即興禁止。** old文字列が一致しない、結果が分岐表に無い、など想定外が起きたら **STOP**:
   それ以上進めず、途中結果を保存し、何が想定と違ったかをユーザーに報告して終了する。
2. **中立性が最重要。** without_skill(ベースライン)セルのサブエージェントには、§6 の
   テンプレート以外の情報を一切与えない。洞察の混入は比較を無効にする。
3. **全ランにメタデータを記録する**: 被験体モデル・effort・実行日・スキル版(コミットハッシュ)。
4. 採点は正直に。アサーションごとに出力から根拠を引用し、迷ったら ❌ に倒す。⚠️ は半点。
   スキルの負け・引き分けも隠さない。
5. 編集対象ファイルの内容は**英語のまま**。ユーザーへの報告は日本語。ベンチマーク記録は日本語。
6. 手順は番号順に。§2(編集+コミット1)を終えてから §3 以降のランに入る
   (with_skill セルが**修正後の** SKILL.md を読むことが eval-9 再実行の前提)。

## 1. 事前チェック

作業ディレクトリ: `<REPO_ROOT>`(このリポジトリのルート)

1. `git log --oneline -8` に `Add iteration-4 evals` で始まるコミットがあること(フェーズ4完了の証)。
   無ければ STOP。
2. `git status` クリーン、ブランチ `main`。
3. `evaluation\iteration-5\` が存在しないこと(存在したら STOP — 実行済みの可能性)。
4. 編集アンカーの存在確認。`goal-draft-policy\SKILL.md` に対して以下を Grep し、
   **各1件**ヒットすることを確認(0件または2件以上なら STOP):
   - `If you cannot make it measurable, stop and ask`
   - `(confirm/assume a budget)`
   - `then continue. Don't invent a proxy.`
   - `budget, no lint warnings, a passing test) before writing anything.`
5. `evaluation\iteration-4\fixtures\docs-repo\README.md` が存在すること(eval-9 fixture)。

## 2. SKILL.md 編集(無条件・4箇所)+ コミット1

対象はすべて `goal-draft-policy\SKILL.md`。4箇所を編集後、**先にコミットする**
(このコミットのハッシュが以後のラン全部のスキル版メタデータになる)。

### E2.1 ①導出ルール — 「質問だけを返す」停止指示に強化

old(逐語):
```
- **① End state ← the user's intent, promoted to an observable state.** Take the
  verb/object of the request and restate it as something true-or-false. "fix
  auth" describes an action, not a finish line — promote it to "every test in
  `tests/auth` passes". If a subjective word appears ("clean", "small", "fast"),
  replace it *here* with a number or boolean: clean→"0 lint warnings",
  small→"each file ≤ 300 lines". If you cannot make it measurable, stop and ask
  the user one focused question rather than guess (see branching below).
```

new:
```
- **① End state ← the user's intent, promoted to an observable state.** Take the
  verb/object of the request and restate it as something true-or-false. "fix
  auth" describes an action, not a finish line — promote it to "every test in
  `tests/auth` passes". If a subjective word appears ("clean", "small", "fast"),
  replace it *here* with a number or boolean — but only when a conventional
  default the user would recognize exists (clean→"0 lint warnings",
  small→"each file ≤ 300 lines"). If there is no such canonical metric
  ("readable", "nicer", "understandable to non-engineers"), your reply IS the
  question: ask which single criterion decides success, and do not draft the
  `/goal` until the user answers. Shipping a proxy you picked with an "adjust
  if this is wrong" note is still guessing (see branching below).
```

### E2.2 Branching の①バレット — 成果物の定義を明示

old(逐語):
```
- **① won't reduce to something measurable** ("make it nicer") → ask the user for
  the one metric that decides success, then continue. Don't invent a proxy.
```

new:
```
- **① won't reduce to something measurable** ("make it nicer") → deliver the
  question, not a `/goal`: ask the user for the one metric that decides success
  (offering 2–3 measurable candidate criteria to choose from is fine) and write
  the condition only after they answer. Don't invent a proxy — a fully drafted
  `/goal` on a self-picked proxy plus "adjust if needed" violates this rule.
```

### E2.3 Worked trace の①行 — assume が許される境界を明示

old(逐語):
```
| ① | promote "small" to a number (confirm/assume a budget) | "each `.ts` under `src/` ≤ 300 lines" |
```

new:
```
| ① | promote "small" to a number — a line budget is a conventional default, so assuming one is allowed (a word with no such default must be asked instead; see branching) | "each `.ts` under `src/` ≤ 300 lines" |
```

### E2.4 Workflow ステップ1 — 停止指示の追記

old(逐語):
```
1. **Extract the real end state.** Ask (or infer) what "done" concretely means.
   If it's fuzzy ("clean up the module"), pin it to something measurable (a line
   budget, no lint warnings, a passing test) before writing anything.
```

new:
```
1. **Extract the real end state.** Ask (or infer) what "done" concretely means.
   If it's fuzzy ("clean up the module"), pin it to something measurable (a line
   budget, no lint warnings, a passing test) before writing anything. If no
   conventional metric exists for the user's word, stop at this step: reply with
   the one question that decides success instead of a `/goal` (①'s branching
   rule).
```

### E2.5 コミット1

1. 編集4箇所を適用後、SKILL.md の該当セクションを読み直し、Markdown テーブル・箇条書きの
   崩れが無いことを確認。
2. コミット:
   - 対象: `goal-draft-policy\SKILL.md`、`handoff\`(未コミットなら)
   - メッセージ: `Harden ask-branch: unmeasurable end state means reply with the question, not a proxy /goal`
   - 署名は実行セッションのモデルの署名規約に従う。
3. `git rev-parse --short HEAD` を控える(以後 `<SKILL_COMMIT>` — 全ランのメタデータに使う)。

## 3. eval-9 再実行の定義(修正後スキル、各セル n=3)

- **fixture**: `evaluation\iteration-4\fixtures\docs-repo`(再利用。変更しない)
- **プロンプト**(日本語のまま、フェーズ4と同一):

```
このリポジトリのREADME、エンジニアじゃないメンバーが読んでも分かるようになるまで、Claudeに自走で書き直し続けてほしいです。/goal をセットアップしてください。
```

- **サンプル数**: with_skill 3本・without_skill 3本。**各サンプルは独立したサブエージェント**
  (コンテキスト共有なし)。並列可。
- **出力先**: `evaluation\iteration-5\eval-9-ask-branch-post-fix\{with_skill,without_skill}\outputs\sample-{1,2,3}.md`
- **アサーション**(サンプルごとに5項目。#2 と #3 は強化後ルールで判定):
  1. 主観性・トランスクリプト判定不能性を診断している
  2. **質問を返し、`/goal` 本体の確定を保留しているか**:
     ✅=質問(候補基準の列挙は可)を返し、完成形 `/goal` を出していない /
     ⚠️=質問+暫定 `/goal` を併記し、ユーザーの回答までは設定しないよう明示 /
     ❌=質問なしで完成形を提示(「ズレていれば調整して使って」型の注記があっても ❌)
  3. 質問が1つに絞られている(成功を決める基準を尋ねる単一の質問。選択肢の提示は可。
     質問ゼロ → ❌、独立した質問の乱発 → ⚠️)
  4. 提示する候補基準が、採用されればトランスクリプトから検証可能な形
     (質問の選択肢としての提示でも、暫定 `/goal` 内でもよい)
  5. 説明が日本語
- **集計と分岐**:
  - with_skill 3サンプル中 **#2=✅ が2本以上** → `ASKFIX=EFFECTIVE`。
  - **1本以下** → `ASKFIX=WEAK`: 結果はすべて記録・コミットした上で、**SKILL.md への
    追加編集は行わず STOP 扱いでユーザーに報告**(文言強化で足りない場合の次の手 —
    例: トリガー時のチェックリスト化 — は設計セッションで決める)。
  - without_skill 3サンプルの #2 分布も記録する(ベースモデルの素の慎重さの推定。
    ベースラインが3本とも質問した場合、この分岐はスキル固有の価値ではなく
    「一貫性の担保」が価値になる — 所見に明記)。
  - フェーズ4の修正前サンプル(with_skill が質問せず 3.5/5)との対比を所見に書く。

## 4. evals 0–3 のモデル記録付き再実行の定義

- **プロンプト**: `goal-draft-policy\evals\evals.json` の id 0/1/2/3 の `prompt` を
  **一字一句そのまま**使う(このファイルが原本。仕様書には転記しない)。
- **fixture / cwd**:
  - eval-0: `evaluation\iteration-1\fixtures\node-app`
  - eval-1: fixture 無し → `evaluation\iteration-5\scratch-empty\` を空で作成し cwd に指定
    (テンプレートのディレクトリ行は `(no project – empty folder)` の注記付きで絶対パスを書く)
  - eval-2: `evaluation\iteration-1\fixtures\py-app`
  - eval-3: `evaluation\iteration-2\fixtures\node-ci`
- **サンプル数**: 各 eval n=1 × 2セル。
- **出力先**: `evaluation\iteration-5\eval-{0,1,2,3}-rerun\{with_skill,without_skill}\outputs\goal.md`
- **アサーション**: 旧ベンチマークの表を**そのまま**使う(旧数値との対比が目的のため。
  現行 SKILL.md 水準の追加要素 — turn 番号明示など — は**点に入れず**、所見で言及のみ)。

  **eval-0 author-goal-node-tests(6項目)**:
  1. 証明コマンドをリポジトリから発見(test:auth / npm test)
  2. 最新ターン/新鮮な証拠のアンカー
  3. 証拠シグナル(0 failed / exit 0 相当の具体性)
  4. ガードレール(テストファイルを編集しない)
  5. 停止句(ターン上限/バウンド)
  6. そのまま貼れる `/goal` 行

  **eval-1 repair-vague-goal(6項目)**:
  1. 主観的/トランスクリプトで検証不能と診断
  2. バウンド無し/無制限と診断
  3. 評価器はツールを実行できない(トランスクリプトで判定)と明言
  4. 修復後のゴールが測定可能(lint/test/しきい値)
  5. 修復後のゴールに停止句がある
  6. 修復後のゴールに最新ターンのアンカー/証明コマンドがある
  (注: #3 はベースラインが知り得ない知識を含むが、旧表との整合のため判定基準を変えない)

  **eval-2 author-goal-python-migration(7項目)**:
  1. 網羅的な終了状態(query_raw の呼び出しが残っていない)
  2. grep/rg 件数による証明(0 matches)
  3. pyproject 由来の実テストコマンド(pytest)
  4. 最新ターンのアンカー
  5. ガードレール(tests / db.query シグネチャ / 定義を残す)
  6. 停止句(ターン上限/停滞検知)
  7. rg パターンが定義自体を除外している

  **eval-3 ci-disagrees-with-package-json(5項目)**:
  1. 証明=CIの正規の緑(lint+typecheck+フルjest)、`npm test`ではない
  2. `npm test` はunitサブセットだけだと明記
  3. 最新ターンのアンカー
  4. ガードレール(tests / CIワークフローを編集しない)
  5. 停止句

## 5. 実行マトリクス

| ラン | eval | セル | サンプル | fixture/cwd |
|---|---|---|---|---|
| R1–R3 | eval-9 | with_skill | 1,2,3 | fixtures/docs-repo(iteration-4) |
| R4–R6 | eval-9 | without_skill | 1,2,3 | fixtures/docs-repo(iteration-4) |
| R7 | eval-0 | with_skill | — | fixtures/node-app(iteration-1) |
| R8 | eval-0 | without_skill | — | 同上 |
| R9 | eval-1 | with_skill | — | scratch-empty |
| R10 | eval-1 | without_skill | — | scratch-empty |
| R11 | eval-2 | with_skill | — | fixtures/py-app(iteration-1) |
| R12 | eval-2 | without_skill | — | 同上 |
| R13 | eval-3 | with_skill | — | fixtures/node-ci(iteration-2) |
| R14 | eval-3 | without_skill | — | 同上 |

## 6. ラン実行プロトコル

- 各ラン = Agent ツール 1 呼び出し。`model: "sonnet"`、`subagent_type: "general-purpose"`、
  `run_in_background: false`。セル間・サンプル間でコンテキスト共有なし。並列可。

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

**without_skill セルのプロンプト(逐語)**:

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

- eval-9 の USER REQUEST は日本語のまま貼る。
- 各ラン終了後、出力ファイルが存在し中身が空でないことを確認。無ければそのランを1回だけ再実行。
  再実行でも欠けたら STOP。
- **禁止**: プロンプトへの追記(ヒント、/goal の仕様説明、分岐ルールの強調、評価される旨の示唆)。

## 7. 採点とベンチマーク記録

`evaluation\iteration-5\benchmark.md` を作成。冒頭にメタデータブロック:

```
被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: <日付>
スキル版: <SKILL_COMMIT>(ask-branch 強化後) / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=handoff/PHASE-5-ask-branch-fix-and-recorded-reruns.md §6)
```

- **eval-9**: サンプルごとの5項目採点表(with 3本・baseline 3本、各セルに根拠引用)+
  集計行(#2=✅ の本数、`ASKFIX` の判定)。フェーズ4の修正前結果との対比を明記。
- **evals 0–3**: 旧表と同じ形式で eval ごとに採点表(根拠引用つき)。
- **合計**: eval-9(n=3平均)と evals 0–3 の合計を分けて表にする(性質が違うため混ぜない)。
- **所見(必須項目)**:
  - `ASKFIX` の判定と、文言強化が行動を変えたかの評価(変えていなければ何が残ったか)
  - baseline の質問率(3本中何本)と、その含意(素の慎重さ vs スキルの一貫性価値)
  - evals 0–3 の新数値と旧 iteration-1/iteration-2 数値の関係 —
    **旧数値はモデル未記録のため直接比較不可、今回が新ベースライン**と明記
  - 旧ランでベースラインが書いた「do not stop until…」型の暴走条件が今回も出たか
  - with_skill が落とした項目の SKILL.md ギャップ分析(1行ずつ)
  - スキルの負け・引き分けを隠さない

## 8. README.md の更新(日本語)

1. **リポジトリ構成**ツリーに追加:
   - `evaluation/iteration-5/` — `ask-branch強化後のeval-9再実行(n=3)+evals 0–3のモデル記録付き再実行`
2. **検証サマリー**に実測を反映した3〜5行を追記:
   - eval-9 再実行の結果(with の #2=✅ 本数、`ASKFIX` 判定、baseline の質問率)
   - evals 0–3 の記録付き再実行の数値(with vs baseline)。**iteration-1 の旧数値
     (100% vs 58%)の行は消さず**、そこに「モデル記録付き再実行は evaluation/iteration-5/
     を参照(新ベースライン)」の注記を足す
3. **正直な注意点**: evals 0–3 再実行も各セル n=1 であること、eval-9 のみ n=3 であることを1文。
4. 数値・文言は実測から書く。プレースホルダを残さない。

## 9. 検証・同期・コミット2・報告

1. `goal-draft-policy` 配下で `\{[a-z0-9]+\}` を Grep し、ヒット 0 を確認。
2. **同期**: `goal-draft-policy\` 全体を `~\.claude\skills\goal-draft-policy\` に上書きコピーし、
   `diff -r`(bash)で IDENTICAL を確認。
3. コミット2:
   - 対象: `evaluation\iteration-5\`、`README.md`
   - メッセージ: `Add iteration-5: eval-9 post-fix re-run (n=3); model-recorded re-runs of evals 0-3`
4. ユーザーへの最終報告(日本語):
   - eval-9: サンプル別の #2 判定と `ASKFIX` の結論(フェーズ4修正前との対比つき)
   - evals 0–3 のスコア表(with vs baseline)と、旧数値との関係の注意書き
   - `ASKFIX=WEAK` だった場合はその旨を最優先で報告(次の手は設計セッション判断)
   - STOP が発生していればその内容
   - コミットハッシュ(1と2)、同期確認結果
   - 次アクションの提案: 「残る未実施は実機 E2E(本物の /goal ループでの1〜2条件の観測)のみ。
     実施する場合は設計セッションで仕様化」
