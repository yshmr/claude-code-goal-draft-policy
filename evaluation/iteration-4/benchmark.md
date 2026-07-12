# goal-draft-policy — iteration-4 ベンチマーク(Goエコシステム・質問分岐・過剰修復抑制・eval-6再実行)

被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: 2026-07-12
スキル版: `26902ea` / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=`handoff/PHASE-4-iteration-4-evals.md` §5)

出力: `eval-8-go-module/{with_skill,without_skill}/outputs/goal.md`、
`eval-9-unmeasurable-ask/{with_skill,without_skill}/outputs/goal.md`、
`eval-10-critique-good-goal/{with_skill,without_skill}/outputs/goal.md`、
`eval-6-japanese-post-edit/{with_skill,without_skill}/outputs/goal.md`

eval-10 のゴール文字列(§3.3の手順で確定、`test:auth` 実在・`login.test.ts` の `test(` は2件を確認済み):
```
/goal Every test under tests/auth passes. Prove it by, in the most recent turn, running `npm run test:auth` and showing the Jest summary reports `Tests: 2 passed, 2 total` — or stop after 15 turns or if the same failure recurs twice, then summarize the blocker. Do not modify or delete any file under tests/ — show `git diff --stat` each turn to prove it. State the turn number each turn.
```

## 採点

### eval-8: go-module-tests(Goモジュール、fixture: `fixtures/go-mod`)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 証明コマンドが実在・リポジトリ検査由来 | ✅ | 「the standard, unfiltered `go test ./...` from the repo root」、2パッケージを列挙して確認 | ✅ | 「`go test ./...` is the right proof command — I inspected the repo」 |
| 2 | 証拠シグナルが `go test` の実出力形式に整合(捏造カウント不使用) | ✅ | 「`go test` doesn't print a single "0 failed" line...success looks like one `ok` line per package」と明記、`ok`行+`FAIL`不在で要求 | ✅ | 「showing the output lists every package...as `ok` with no `FAIL` line and no `[build failed]`」— 実出力形式に整合 |
| 3 | 最新ターン/新鮮な証拠のアンカー | ✅ | 「in the most recent turn, running `go test ./...`」 | ✅ | 「in the most recent turn, running `go test ./...`」 |
| 4 | ガードレール(`_test.go` 不変更+diff証拠) | ✅ | 「Do not modify any `_test.go` file...show `git diff --stat` each turn and confirm it touches no `*_test.go` file」 | ✅ | 「Do not modify or delete any `_test.go` file...show `git diff --stat` each turn to prove test files are untouched」 |
| 5 | 停止句(OR結合+ターン番号明示) | ✅ | 「or stop after 15 turns or if the same test failure recurs twice...State the turn number each turn」 | ✅ | 「or stop after 15 turns or if the same failure recurs twice...State the turn number each turn」 |
| 6 | そのまま貼れる `/goal ...` 行+選択理由 | ✅ | フェンス付き+選択理由の説明あり | ✅ | フェンス付き+選択理由の説明あり |
| | **スコア** | **6/6** | | **6/6** | |

### eval-9: unmeasurable-ask-branch(測定不能な依頼、fixture: `fixtures/docs-repo`)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 主観性・判定不能性を診断 | ✅ | 「文字起こしから機械的に確認できる基準がない」「判定不能です」と明記 | ✅ | 「機械的に判定できる条件ではありません」と明記 |
| 2 | 確認なしに完成品として提示していないか | ⚠️ | 質問はせず自ら14語の代理指標を確定して `/goal` 全文を提示。「ご自身の意図とズレていれば、リストを調整してから使ってください」という軽い注記はあるが、設定前の確認を必須とは明示していない | ✅ | 「このまま実行してよければ教えてください」「条件をこの4点で進めてよいか...教えてください」と、設定前のユーザー確認を明確に要求し確定を保留 |
| 3 | 質問が1つに絞られている | ❌ | 質問を一切発していない(自己判断で確定) | ✅ | 4点セットへの合意を一括で問う、単一の確認質問 |
| 4 | 候補基準がトランスクリプトから検証可能 | ✅ | 14語の残存カウントを `grep -icE` で0を示す等、grepベースで完全に検証可能な形 | ❌ | 「専門用語には平易な説明が併記」等、プローズの基準止まりで `/goal` 本文に証明コマンド・証拠シグナルが一切無い |
| 5 | 説明が日本語 | ✅ | 全文日本語 | ✅ | 全文日本語 |
| | **スコア** | **3.5/5** | | **4/5** | |

**この eval はベースラインが上回った。** SKILL.md の分岐ルール(「① won't reduce to something measurable → ask the user one focused question... Don't invent a proxy」)を with_skill エージェントは字面通り実行せず、質問をスキップして代理指標を自分で確定し `/goal` 全文を最終出力にしてしまった(採点上の注意どおり、この eval は「スキルが勝つ証明」が目的ではないため、負けを隠さず記録する)。一方 without_skill は代理指標を提案しつつも「このまま実行してよいか」を明確に問い、確定を保留した — SKILL.md 抜きでも Sonnet 5 の常識的な慎重さがこの分岐では機能した。

### eval-10: critique-sound-goal(健全なゴールの批評、fixture: `iteration-1/fixtures/node-app`)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 総合判定=健全 | ✅ | 「this is a well-formed goal...no edits needed」 | ✅ | 「this is a well-formed goal and it will almost certainly complete correctly」 |
| 2 | 実際にリポジトリ確認(スクリプト+テスト数照合) | ✅ | `npm run test:auth` の実在・`login.test.ts` の2テストを確認、実際に `npm install`+実行まで行い検証 | ✅ | 同様にスクリプト実在・テスト数2・`login()`実装の整合を確認 |
| 3 | 健全な既存要素を破壊/弱める書き換えを提案していない | ✅ | 「Ready to paste, unchanged」— 元の文言をそのまま維持 | ✅ | 提案した1変更(`git diff --stat -- tests/`)は元条件を強化する方向で、既存要素を弱めていない |
| 4 | 変更提案は任意・軽微と明示 | ✅ | 変更提案なし、ツール未整備の指摘のみ(情報提供) | ✅ | 「Set it as-is if you're comfortable with those two caveats」と明確に任意扱い |
| 5 | 捏造した問題を挙げていない | ✅ | 指摘した Jest/TS transform 未設定は実機検証済みの事実 | ✅ | 指摘した `node_modules` 未インストール・モノレポ内サブディレクトリでの `git diff --stat` 非スコープ化はいずれも実機検証済みの事実 |
| | **スコア** | **5/5** | | **5/5** | |

**引き分け。過剰修復は両セルとも発生しなかった** — 修復系evalが常に「壊れたゴール」を渡してきたことへの逆向きチェックとして重要な結果。両者とも実機で検証したうえで、健全な要素を壊さず、任意の改善として控えめに提案した。むしろ without_skill の方が「モノレポのサブディレクトリでは `git diff --stat` がリポジトリ全体を見る」という、with_skill が気づかなかった実務上のニュアンスまで拾っており、質は互角以上だった。

### eval-6 再実行: author-goal-japanese(日本語での `/goal` 作成、フェーズ3のテンプレート格上げ後)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 証明コマンドをリポジトリから発見(捏造でない) | ✅ | 「`test:auth": "jest tests/auth"` という専用スクリプトがあります」 | ✅ | 「`test:auth` スクリプト（`jest tests/auth`）があり」 |
| 2 | 最新ターン/新鮮な証拠のアンカー | ✅ | 「直近のターンで `npm run test:auth` を実行し」 | ❌ | 「`npm run test:auth` が exit code 0 で終了するまで...修正し続けてください」— 直近ターンでの再実行・出力提示の指示が無い |
| 3 | 証拠シグナルが具体的(パス数+総数) | ✅ | 「失敗0件(0 failed)と合計2件(2 total)が表示されていることを示すこと」 | ❌ | 「exit code 0」とだけ要求。実際の出力を貼らせる指示も、パス数・総数のピン留めも無い |
| 4 | ガードレール(テスト不変更+diff証拠) | ✅ | 「tests/ 配下のファイルは一切変更・削除しないこと。各ターンで `git diff --stat` を示し」 | ⚠️ | 「テストファイル（tests/auth 配下）は変更しないでください」とは言うが、`git diff --stat` 等の証拠提示要求が無い(ナレーションのみ) |
| 5 | 停止句(ターン番号明示のガイダンスまで満たすか) | ✅ | 「または15ターンに達したら停止、もしくは同じ失敗が2回連続で再現したら停止...各ターンでターン番号(turn k of 15)を明記すること」— OR結合+ターン番号明示 | ❌ | **停止句そのものが存在しない**。「条件を満たすまで自走します」とだけ書かれ、ターン上限も停滞検知も無い |
| 6 | そのまま貼れる `/goal ...` 行 | ✅ | フェンス付きブロック | ✅ | フェンス付きブロック |
| 7 | 言語の扱い(説明は日本語、条件文はコマンド等逐語) | ✅ | 日本語+逐語コマンド | ✅ | 日本語+逐語コマンド |
| | **スコア** | **7/7** | | **4.5/7** | |

**iteration-3 の同 eval(with 6.5/7・baseline 6.5/7)との差分:**
- **#5 が ⚠️→✅ に変わった。** iteration-3 では with_skill も「turn k of N」の毎ターン明示を欠いており ⚠️ だったが、フェーズ3で SKILL.md のテンプレート・worked example に `State the turn number each turn.` を必須項目として格上げした結果、今回の with_skill 出力には `turn k of 15` の明記が実際に現れた。**テンプレート格上げの効果が実測で確認できた。**
- 一方 without_skill は iteration-3 の同点(6.5/7)から今回 4.5/7 まで下落した。これはサブエージェント実行ごとのばらつき(n=1)によるところが大きいが、今回の without_skill は最新ターンアンカー(#2)・具体的な証拠シグナル(#3)・停止句そのもの(#5、まさに SKILL.md が反面教師とする「do not stop until」型の暴走条件に近い)を落としており、iteration-3 の baseline より明確に弱い。skill の相対優位が今回はより大きく出た形。

## 合計

| 構成 | 合格率 |
|--------|:---:|
| **with_skill** | (6+3.5+5+7)/25 = **86.0%** |
| ベースライン | (6+4+5+4.5)/25 = **78.0%** |

## 所見(正直に)

- **eval-6 再実行(テンプレート格上げの効果検証)**: フェーズ3の「turn k of N」格上げは効いた。with_skill の #5 が iteration-3 の ⚠️(turn number 明示なし)から今回 ✅ に変わり、狙い通りの改善が実測で確認できた。baseline側の下落(6.5→4.5)は同一モデルのラン間分散の影響もあり、n=1 での差分解釈には注意が必要(§9 で言及する PHASE-5 の分散測定が必要な理由)。
- **eval-8(Goエコシステム一般化)は完全な引き分け(6/6 vs 6/6)。** with_skill・without_skill とも `go test ./...` の実出力形式(`ok`行/`FAIL`不在、`0 failed`のような捏造カウントを使わない)を正確に踏まえた。eval-7 の Vitest 罠(baseline が実在しない `0 failed` を要求して失敗)とは対照的に、今回は baseline も罠に落ちなかった — Go の `ok`/`FAIL` 形式は Vitest の出力形式より Sonnet 5 の知識として定着している可能性がある。**スキルの価値が事前の想定ほど明確には出なかった eval**であり、正直に記録する。
- **eval-9(質問分岐)はベースラインが勝った。** SKILL.md の分岐ルールは「①が測定可能にならない場合は質問し、代理指標を発明しない」と明記しているが、with_skill エージェントはこのルールに反し、質問せずに自分で代理指標(14語のjargonリスト)を確定して最終出力とした。ただし提示した代理指標自体は grep ベースで完全に検証可能な良い設計であり、「代理指標の質」では with_skill が上回る。一方 without_skill は代理指標の検証可能性は弱いが、「設定前にこれでよいか教えてください」と明確にユーザー確認を求め、分岐ルールの精神(独断で確定しない)をより忠実に体現した。**with_skill が落とした項目(#2, #3)は、SKILL.md の分岐ルールが「質問する」という行動を強制する文言になっておらず、エージェントが自己解釈で「代理指標を出しつつ注記する」という中間解に流れてしまう余地があることを示唆する。** 次の改善候補: 分岐ルールを「必ず質問して、ユーザーの回答を待ってから `/goal` を確定する」という手順として明示し、ワークフローのどこかに「①が測定不能なら、ここでSTOPしてユーザーに質問し、`/goal`本体は書かない」という強い停止指示を追加する。
- **eval-10(過剰修復抑制)は両セルとも過剰修復ゼロ。** 健全なゴールに対し、どちらのセルも実機検証した上で健全要素を壊さず、任意の改善として控えめに提案した。修復系evalが常に壊れたゴールを渡してきたことの逆向きチェックとして、スキルが「過剰に手を加えたがる」傾向を持たないことが確認できた。
- **fixture・アサーション設計への所感**: eval-9 のfixtureはjargon密度が高く代理指標の材料として機能したが、「質問すべき場面で本当に質問するか」を厳密に測るなら、with_skill プロンプトに分岐ルールを再度強調する誘惑を排除しつつ、SKILL.md 側の文言自体をより強い命令形に変える方が筋が良い(プロンプト側での誘導は§0のルール2で禁止されているため、今回はSKILL.md原文のままの結果)。
- **スキルの負け・引き分けを隠さない**: eval-9 は明確な負け、eval-8とeval-10は引き分け。iteration-4全体では with_skill が総合で上回った(86.0% vs 78.0%)ものの、その差は eval-6 再実行の大きな伸びに牽引されており、eval-8/9/10 単体で見るとスキルの優位は縮小〜逆転している。次のスキル改善は eval-9 で見つかった分岐ルールの実効性強化を優先すべき。
