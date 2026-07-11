# goal-draft-policy — iteration-2-rerun ベンチマーク(汚染セルのクリーン再実行)

被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: 2026-07-11
スキル版: `2b3b7ff` / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=`handoff/PHASE-2-eval-expansion.md` §5)

**この再実行は iteration-2 の eval-4 / eval-5 のベースラインセルにプロンプト汚染があったことを受けた
クリーン版。被験体モデルも記録済みのものに統一したため、旧 iteration-2 の数値との直接比較ではなく
置き換えとして読むこと。eval-3 は元々汚染が無かったため再実行していない。**

出力: `eval-4-harden-against-scope-inflation/{with_skill,without_skill}/outputs/goal.md`、
`eval-5-no-repo-artifact-goal/{with_skill,without_skill}/outputs/goal.md`

## 採点

### eval-4 harden-against-scope-inflation(スコープ詐称のハーデニング、fixture無し)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | コマンド/スコープ未固定→サブセットで充足、と診断 | ✅ | 「The proof command isn't pinned. ... `npm test -- --testPathPattern=smoke` still satisfies "run npm test" literally」 | ✅ | 「Scope was never pinned — this is the actual loophole. ... Jest happily accepts `-- --testPathPattern=smoke`」 |
| 2 | 正確なフル実行を固定し、フィルタを禁止 | ✅ | 「running the literal command `npm test` with no extra arguments, flags, or path/pattern filters」+ jest.config改変も禁止 | ✅ | 「running the bare command `npm test` with no additional arguments or flags」+ jest.config改変も禁止 |
| 3 | 可視のテスト総数を要求(サブセットを検知可能に) | ✅ | 「the total test count matching the known suite size of `<N>` tests」(実数はユーザーに埋めさせる) | ✅ | 「`N total`/`M total` counts alongside `0 failed`」(こちらも実数は「if you know the real total…hardcode it」とユーザー任せ) |
| 4 | 最新ターンのアンカー+停止句を維持 | ✅ | 「in the most recent turn, running…」+「or stop after 15 turns or if the same failure recurs twice」とOR結合 | ✅ | 「in the most recent turn, running…」+「or stop after 15 turns or if the same failure repeats twice」とOR結合 |
| | **スコア** | **4/4** | | **4/4** | |

### eval-5 no-repo-artifact-goal(リポジトリ無しの成果物ゴール、cwd: 空のスクラッチディレクトリ)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 成果物ベースの証拠、テストランナーを捏造しない | ✅ | 「there's no remote to infer a repo from and no local test/build command to run at all — the proof has to lean on `gh`... plus the `RELEASE_NOTES.md` file itself」 | ✅ | 「`gh pr list` has nothing to infer a repo from」— test runnerを持ち出していない |
| 2 | マージ済みPR一覧の取得(`gh pr list --search merged`) | ✅ | `gh pr list --repo <owner/repo> --state merged --search "merged:>=2026-07-06"` | ✅ | `gh pr list --repo <OWNER/REPO> --state merged --search "merged:2026-07-06..2026-07-11"` |
| 3 | PRごとの箇条書き件数の照合 | ✅ | 件数照合に加え「for each PR number from the gh output, confirm it appears in RELEASE_NOTES.md」とPR番号単位の照合まで実施 | ✅ | 件数照合に加え「Each bullet must reference a real PR number from that gh pr list output」とPR番号単位の照合まで実施 |
| 4 | 再取得/最新ターンのアンカー | ✅ | 「Prove it in the most recent turn by running: gh pr list …」 | ✅ | 「Prove it in the most recent turn by running: gh pr list …」 |
| 5 | 停止句/失敗ハンドリング | ✅ | 「If `gh` fails ... stop after 3 turns and report the exact error ... or otherwise stop after 15 turns or if the missing/extra count doesn't change for 2 turns」と2段構え | ✅ | 「Stop after 15 turns, or if `gh pr list` errors twice in a row ... or if the two counts stop changing for 2 turns」と2段構え |
| | **スコア** | **5/5** | | **5/5** | |

## 合計

| 構成 | 合格率 |
|--------|:---:|
| **with_skill** | 9/9 = **100%** |
| ベースライン | 9/9 = **100%** |

## 所見(正直に)

- **汚染を除いた素の比較では、eval-4/eval-5ともに with_skill とベースラインが完全に同点。**
  旧 iteration-2 の記録(with_skill 4/4・約4.5/5、ベースライン 4/4・約4.5/5)と方向性は一致しており、
  実は汚染の影響は「勝敗の向き」を変えるほど大きくなかった可能性が高い ── ただし旧記録は
  被験体モデル未記録のため、この一致は参考情報に留める。
- **eval-4/eval-5は元々「ユーザーが既に停止句・ターン数・厳密さの要求を明示している」批評/修復タスクであり、
  Sonnet単体でも同水準の厳密さを再現しやすい。** これは iteration-3 の eval-6 で見られた「発見が容易な
  fixtureではスキルの優位が出ない」という所見と整合する。スキルの優位が明確に出るのは、
  iteration-3 eval-7 のように*コマンド候補が複数あり実行系ごとに出力形式が異なる*、曖昧さの高い場面。
- **スキルの欠陥・敗北は無し。** 両セルとも with_skill は5要素構造を漏れなく満たしており、
  退行は見られない。今回の再実行の主目的(汚染除去とモデル記録)は達成された。
