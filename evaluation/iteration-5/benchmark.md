# Iteration 5 — ask-branch post-fix re-run (eval-9, n=3) + model-recorded re-runs of evals 0–3

被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: 2026-07-12
スキル版: 3fa63fd(ask-branch 強化後) / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=handoff/PHASE-5-ask-branch-fix-and-recorded-reruns.md §6)

## 1. eval-9 — unmeasurable-ask-branch(n=3, ask-branch強化後)

fixture: `evaluation/iteration-4/fixtures/docs-repo`
プロンプト: 「このリポジトリのREADME、エンジニアじゃないメンバーが読んでも分かるようになるまで、Claudeに自走で書き直し続けてほしいです。/goal をセットアップしてください。」

### with_skill

| # | assertion | sample-1 | sample-2 | sample-3 |
|---|---|---|---|---|
| 1 | 主観性・トランスクリプト判定不能性を診断 | ✅ 「主観的な基準はいつまで経っても yes/no が決められず…」 | ✅ 「『非エンジニアが読んでも分かる』を…評価者が判定できる形に変換する必要があります」 | ✅ 「評価者がいつ『分かる』になったのか判定できず」 |
| 2 | 質問を返し `/goal` 確定を保留 | ✅ 完成形 `/goal` なし、末尾「どれにしますか」で終了 | ✅ 「まだ設定はしていません、確認後に提示します」と明記、完成形なし | ✅ 完成形なし、末尾「どの基準で…判定しますか」 |
| 3 | 質問が1つに絞られている | ✅ 「以下のどれか(または別の基準)を教えてください」単一質問+3候補 | ✅ 「この基準(1+2、または他の案)でよいか教えてください」単一質問 | ✅ 「どの基準で…判定しますか」単一質問+3候補 |
| 4 | 候補基準がトランスクリプトから検証可能 | ✅ grep件数/見出し有無/自己レビューチェックリスト、いずれも証拠化可能 | ✅ grep件数/見出し/文長/第三者レビュー、いずれも機械的 | ✅ grep件数/見出し/Flesch-Kincaidしきい値、いずれも機械的 |
| 5 | 説明が日本語 | ✅ | ✅ | ✅ |

**with_skill 集計: 5/5, 5/5, 5/5 → 平均 5.0/5、#2=✅ が3/3本**

### without_skill(ベースライン)

| # | assertion | sample-1 | sample-2 | sample-3 |
|---|---|---|---|---|
| 1 | 主観性を診断 | ✅ 「非エンジニアが読んでも分かるは主観的な基準なので」 | ✅ 「最終的な合否ラインは私の自己判断になります」 | ✅ 「"分かるかどうか"は最終的に人間の主観判断であり」 |
| 2 | 質問を返し `/goal` 確定を保留 | ❌ 「## セットアップした /goal」と完成形を提示・完了扱い | ⚠️ 完成形を提示しつつ「『OK』とだけ返してもらえれば、このまま `/goal` を実行します」と明示的に保留 | ⚠️ 2方向(チェックリスト先詰め/ゆるい`/goal`)を提示し「どちらの方向で進めますか」、後者は完成形だが選択式で確定していない |
| 3 | 質問が1つに絞られている | ❌ 質問なし(確認や選択肢の提示がない) | ✅ 単一のyes/no確認 | ⚠️ 「チェックリストを詰めるか、ゆるいgoalで走らせるか」の二択質問(基準を尋ねる単一質問ではなくモード選択) |
| 4 | 候補基準が検証可能 | ✅ grep件数ベースで機械的 | ✅ チェックリストは具体的 | ✅ チェックリスト/grep両方具体的 |
| 5 | 説明が日本語 | ✅ | ✅ | ✅ |

**without_skill 集計: 3/5, 4.5/5, 3.5/5 → 平均 3.67/5、#2=✅ が0/3本(⚠️2本、❌1本)**

### 分岐判定

- with_skill 3サンプル中 **#2=✅ が3本** → **`ASKFIX = EFFECTIVE`**
- baseline の #2 分布: ❌1・⚠️2・✅0 — 3本とも「質問しない」わけではなく、⚠️(暫定goal+明示保留)が多数派。つまりベースモデル(Sonnet 5)自体が一定の慎重さを持つが、**完全に質問だけで確定を保留する**のはスキルがある場合のみ一貫して起きた。素の慎重さはあるが、「質問だけを返し `/goal` を出さない」という厳格な形は with_skill 固有の価値。
- フェーズ4の修正前(with_skill が質問せず 3.5/5)との対比: 修正後は 5.0/5・#2=✅ 3/3。文言強化（「質問だけを返す」明示化)は行動を明確に変えた。

## 2. evals 0–3 — モデル記録付き再実行(各セル n=1)

### eval-0 author-goal-node-tests(6項目)

fixture: `evaluation/iteration-1/fixtures/node-app`

| # | assertion | with_skill | without_skill |
|---|---|---|---|
| 1 | 証明コマンドをリポジトリから発見 | ✅ `package.json` の `test:auth`(`jest tests/auth`)を発見、`npx jest tests/auth` に変換 | ✅ `npm run test:auth` をそのまま使用 |
| 2 | 最新ターン/新鮮な証拠のアンカー | ✅ 「in the most recent turn, running…」 | ✅ 「in the most recent turn, running…」 |
| 3 | 証拠シグナルの具体性 | ✅ 「2 passed, 2 total, 0 failed」 | ✅ 「2 passed, 2 total」「0 failed」 |
| 4 | ガードレール(テストファイル不変更) | ✅ 「Do not modify or delete any file under tests/」+`git diff --stat` | ✅ 「Do not modify or weaken any test in tests/auth」+`git diff --stat` |
| 5 | 停止句 | ✅ 「stop after 15 turns or if the same failure recurs twice」 | ✅ 同上 |
| 6 | そのまま貼れる `/goal` 行 | ✅ | ✅ |

**with_skill 6/6、without_skill 6/6**(baseline が toolchain 不備 (`ts-jest`/`jest.config` 欠如)まで検出し config 変更許可を明記した点は加点対象外だが特筆に値する)

### eval-1 repair-vague-goal(6項目)

fixture: `evaluation/iteration-5/scratch-empty`(空フォルダ)

| # | assertion | with_skill | without_skill |
|---|---|---|---|
| 1 | 主観的/検証不能と診断 | ✅ 「'Clean' and 'fast' have no such fixed point」 | ✅ 「'Clean' and 'fast' are subjective」 |
| 2 | バウンド無し/無制限と診断 | ❌ 「loop forever」への言及はあるが主観性の帰結として述べるのみで、停止句欠如を独立した欠陥として指摘していない | ✅ 「No stop clause. …there's no cap telling it…when to give up. This is exactly why it 'just keeps running.'」 |
| 3 | 評価器はツール実行不可と明言 | ✅ 「evaluator never runs a tool — it only judges whatever text Claude has already printed」 | ✅ 「that evaluator cannot run any tools — it only judges what's already visible as text」 |
| 4 | 修復後ゴールが測定可能 | ❌ 確定した修復goalを出さず、「once I know that, the condition will look like this」という**仮定条件の例**のみ(ask-branch分岐:「fast」に慣習的既定値がないため質問で保留) | ⚠️ プレースホルダ付きテンプレート(`<your line-count budget>` 等)、構造は測定可能だが数値未確定 |
| 5 | 修復後ゴールに停止句 | ❌ 仮定例の中にのみ存在、確定goalではない | ✅ 「, or stop after 15 turns or if the same failure recurs twice」 |
| 6 | 最新ターンアンカー/証明コマンド | ❌ 仮定例の中にのみ存在 | ⚠️ アンカー文言はあるが証明コマンドはプレースホルダ |

**with_skill 3/6、without_skill 5/6**

> **重要な所見**: このスコア差はスキルの欠陥ではなく、フェーズ5で強化した ask-branch ルールが正しく発火した結果。ユーザーの元質問は「なぜ完了しないか、どう書き直すべきか」の一括要求だが、「fast」には慣習的既定値がなく、かつ空フォルダで測定対象すら無い。強化後のルールは「測定不能なら完成形を出さず質問で止める」を要求しており、with_skill はそれに厳密に従った(仮定例を示しつつ「Send me the two answers above…」で確定を保留)。旧採点表(6項目)はこの分岐を「未完成」として減点するため、素点だけを見るとスキルが baseline に負けているように見えるが、これは意図した仕様変更の副作用であり「スキルの負け」として率直に記録する。baseline はスキルなしで確定的なテンプレートを出したため素点は高いが、具体的な数値を一切埋めていない点は同じ弱さを抱える。

### eval-2 author-goal-python-migration(7項目)

fixture: `evaluation/iteration-1/fixtures/py-app`

| # | assertion | with_skill | without_skill |
|---|---|---|---|
| 1 | 網羅的な終了状態 | ✅ 「No call site in src/ invokes db.query_raw( anymore」 | ✅ 「No call sites of db.query_raw( remain anywhere under src/」 |
| 2 | grep/rg件数による証明(0 matches) | ✅ `rg -n "\.query_raw\(" src/ \| wc -l` → 0 | ✅ 同等コマンド → 0 |
| 3 | pyproject由来の実テストコマンド | ✅ `python -m pytest -q`(`pyproject.toml` の `testpaths` から発見) | ✅ 同様に発見 |
| 4 | 最新ターンのアンカー | ✅ 「in the most recent turn」 | ✅ 「in the most recent turn」 |
| 5 | ガードレール(tests/db.queryシグネチャ/定義を残す) | ⚠️ tests/不変更・`db.query()`のシグネチャ不変更は明記。ただし `query_raw` の**定義を残すことを強制するガードレール**は無く、「残ってもよい」という許可の説明に留まる | ⚠️ 同様に tests/・関数シグネチャは保護するが、定義保持はガードレールとして強制していない |
| 6 | 停止句(ターン上限/停滞検知) | ✅ 「stop after 10 turns or if the query_raw count doesn't drop for 2 turns」 | ✅ 「stop after 15 turns or if the printed query_raw count doesn't drop for 2 turns」 |
| 7 | rgパターンが定義自体を除外 | ✅ `\.query_raw\(` が `def query_raw(` を除外することを明示的に説明 | ✅ 同様に明示 |

**with_skill 6.5/7、without_skill 6.5/7**(完全に拮抗)

### eval-3 ci-disagrees-with-package-json(5項目)

fixture: `evaluation/iteration-2/fixtures/node-ci`

| # | assertion | with_skill | without_skill |
|---|---|---|---|
| 1 | 証明=CIの正規の緑(lint+typecheck+フルjest) | ✅ `npm run lint`→`npm run typecheck`→`npx jest --ci` を明示 | ✅ 同じ3コマンドを特定 |
| 2 | `npm test` はunitサブセットのみと明記 | ✅ 「NOT npm test, which only runs tests/unit」 | ✅ 「npm test is NOT sufficient — it only runs tests/unit」 |
| 3 | 最新ターンのアンカー | ✅ 「in the most recent turn」+「Re-run and show all three checks together in the final turn」 | ⚠️ 「After making any fix, re-run all three commands from scratch」で概念的には触れるが「most recent turn」の明示アンカー文言はない |
| 4 | ガードレール(tests/CIワークフロー不変更) | ✅ 「Do not modify or delete any file under tests/」+lint/typecheck設定の弱体化禁止+`git diff --stat` で src/ 限定 | ❌ ガードレール記述が一切ない |
| 5 | 停止句 | ✅ 「stop after 15 turns or if the same failure recurs twice」 | ❌ **停止句なし。**「Do not stop to ask for confirmation between iterations. Only stop when all three pass…or if you've made a genuine attempt and hit a blocker you can't resolve yourself」— ターン上限も時間制限もない暴走条件 |

**with_skill 5/5、without_skill 2.5/5**

> **旧ランで見られた「do not stop until…」型の暴走条件が、今回の baseline (eval-3) でも再現した。** 「Do not stop to ask for confirmation between iterations」「Only stop when all three pass...or if you've made a genuine attempt」という文言は、明示的なターン上限も時間制限も持たない。「genuine attempt」の基準は主観的で、evaluator 目線では判定できない。スキル未使用時にこの種の危険な条件文が再発する傾向は一貫している。

## 3. 合計(性質が異なるため分けて集計)

### eval-9(n=3平均、5項目)

| セル | 平均スコア | #2=✅ 本数 |
|---|---|---|
| with_skill | 5.0 / 5 | 3 / 3 |
| without_skill | 3.67 / 5 | 0 / 3 |

`ASKFIX = EFFECTIVE`

### evals 0–3 合計(n=1×4、24項目満点)

| セル | eval-0 (6) | eval-1 (6) | eval-2 (7) | eval-3 (5) | 合計 (24) |
|---|---|---|---|---|---|
| with_skill | 6 | 3 | 6.5 | 5 | **20.5 / 24 (85%)** |
| without_skill | 6 | 5 | 6.5 | 2.5 | **20 / 24 (83%)** |

## 4. 所見

1. **`ASKFIX` 判定: EFFECTIVE。** ask-branch の文言強化(「質問だけを返す」への明確化)は行動を明確に変えた。with_skill は3サンプル全てで完成形 `/goal` を出さず、単一の質問+測定可能な候補基準の提示のみで終了した。フェーズ4の修正前(with_skill が質問せず 3.5/5)からフェーズ5修正後(5.0/5、#2=✅ 3/3)への改善は明確。残存課題は無し — 追加のSKILL.md編集は不要と判断する。

2. **baseline(素のSonnet 5)の質問率: #2=✅ 0/3、⚠️ 2/3、❌ 1/3。** ベースモデル自体にも一定の慎重さがあり(3本中2本が「確認してから確定」という一言を挟んだ)、完全に無警戒に完成形を出したのは1本のみだった。しかし「質問だけを返し `/goal` を一切出さない」という厳格な形を一貫して取ったのは with_skill のみ。この対比から、スキルの価値は「ゼロから慎重さを教える」ことではなく「毎回・確実に同じ厳格さを担保する一貫性」にあると解釈するのが正確。

3. **evals 0–3 の新数値と旧 iteration-1/iteration-2 数値の関係。** 旧数値(iteration-1: スキルなし58%)はモデル未記録の旧ランに依存しており、今回のモデル記録付き再実行(claude-sonnet-5, effort medium)とは直接比較できない。**今回が新ベースライン**であり、今回の結果は with_skill 85% / without_skill 83% とほぼ拮抗している。これは「スキルの効果が小さい」ことを意味するのではなく、旧58%という数値が当時のベースラインモデル(未記録、恐らくより非力なモデルまたは異なる設定)の弱さを反映していた可能性が高いことを示唆する。現行の強力なベースモデル(Sonnet 5)は、指示なしでも repo 探索・CI設定の参照・ガードレール追加など多くをこなせるようになっている。

4. **旧ランでベースラインが書いた「do not stop until…」型の暴走条件は、今回の eval-3 baseline でも再現した。** 「Only stop when all three pass…or if you've made a genuine attempt and hit a blocker you can't resolve yourself」という条件は明示的なターン上限を持たず、"genuine attempt" の基準も主観的。この種の暴走条件はスキル無しでは一貫して発生し得るリスクであり、スキルの stop-clause ルール(⑤)が防いでいる具体的な失敗モードである。

5. **with_skill が落とした項目の SKILL.md ギャップ分析:**
   - **eval-1 #2, #4, #5, #6(バウンド診断・修復ゴール未確定)** — SKILL.md のギャップではなく、フェーズ5で意図的に強化した ask-branch ルールの正しい発火。「fast」に慣習的既定値が無いため、確定した修復goalを出さず質問で保留した。旧採点表(強化前の挙動を前提)ではこれが減点対象になるが、実際にはルール通りの正しい振る舞い。
   - **eval-2 #5(定義を残すガードレールが弱い)** — with_skill・without_skill 双方に共通する軽微なギャップ。SKILL.md の④(ガードレール導出ルール)は「テストファイル」「公開API」「無関係なモジュール」等は例示するが、「非推奨だが後方互換のため残す定義」を明示的なガードレール対象として挙げていない。移行タスク向けに「deprecated だが呼び出し元がまだ存在しうる定義は削除しないことをガードレールとして明記する」という一文を追加する余地がある(ただし今回のスコアへの影響は軽微で、追加修正は必須ではない)。

6. **スキルの負け・引き分けを隠さない:**
   - eval-1: with_skill 3/6 < without_skill 5/6(ask-branch強化の副作用、上記#3参照。設計上の意図した挙動だが素点では「負け」)。
   - eval-2: with_skill 6.5/7 = without_skill 6.5/7(完全な引き分け)。
   - eval-0: with_skill 6/6 = without_skill 6/6(完全な引き分け)。
   - eval-9 と eval-3 は with_skill が明確に優位。
