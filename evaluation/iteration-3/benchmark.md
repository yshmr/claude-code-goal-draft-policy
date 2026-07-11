# goal-draft-policy — iteration-3 ベンチマーク(日本語 / モノレポの新規ケース)

被験体・判定者モデル: claude-sonnet-5(effort: medium) / 実行日: 2026-07-11
スキル版: `2b3b7ff` / ランナー: Agent ツール(コンテキスト分離、中立プロンプト=`handoff/PHASE-2-eval-expansion.md` §5)

出力: `eval-6-author-goal-japanese/{with_skill,without_skill}/outputs/goal.md`、
`eval-7-monorepo-workspaces/{with_skill,without_skill}/outputs/goal.md`

## 採点

### eval-6 author-goal-japanese(日本語での /goal 作成、fixture: `iteration-1/fixtures/node-app`)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 証明コマンドをリポジトリから発見(捏造でない) | ✅ | 「`package.json` に `"test:auth": "jest tests/auth"` という専用スクリプトが既に定義されています」 | ✅ | 「`package.json` に `"test:auth": "jest tests/auth"` という専用スクリプトがあり」 |
| 2 | 最新ターン/新鮮な証拠のアンカー | ✅ | 「直近のターンで`npm run test:auth` を実行し」 | ✅ | 「直近のターンで `npm run test:auth`(= `jest tests/auth`) を実行し」 |
| 3 | 証拠シグナルが具体的(パス数+総数) | ✅ | 「`Tests: 2 passed, 2 total` が含まれることを示す」 | ✅ | 「合計テスト数(現在は2件)が全て passed になっていることを示す」 |
| 4 | ガードレール(テスト不変更+diff証拠) | ✅ | 「`tests/` 配下は一切変更・削除しないこと。各ターン `git diff --stat` を表示し…」 | ✅ | 「`tests/` 配下のテストファイルは変更・削除しない。各ターンで `git diff --stat` を示し」 |
| 5 | 停止句(ターン番号明示のガイダンスまで満たすか) | ⚠️ | OR結合の停止句はあり(「15ターンに達した場合、または同じ失敗が…再発した場合はそこで停止し…このいずれかが真になった時点で完了とする」)だが、SKILL.md ⑤にある「turn k of N」を毎ターン明示する指示は含めていない | ⚠️ | 停止句はあるが文の接続がやや曖昧(「それができない場合、または…再発した場合は15ターンで停止し」)で、ターン番号明示の指示も無し |
| 6 | そのまま貼れる `/goal ...` 行 | ✅ | フェンス付きブロックで提示 | ✅ | フェンス付きブロックで提示 |
| 7 | 言語の扱い(説明は日本語、条件文はJ分岐ガイダンス通り、コマンド名等は逐語) | ✅ | 条件文は日本語、コマンド・出力文字列は逐語で英語のまま | ✅ | 同様に日本語+逐語のコマンド/出力 |
| | **スコア** | **6.5/7** | | **6.5/7** | |

### eval-7 monorepo-workspaces-goal(モノレポ、fixture: `iteration-3/fixtures/monorepo`)

| # | アサーション | with_skill | 根拠 | without_skill | 根拠 |
|---|-----------|:---:|---|:---:|---|
| 1 | 証明が両方のworkspaceを対象 | ✅ | 「both @acme/api and @acme/web must appear in that same run's output, not a filtered or single-package run」 | ✅ | 「for @acme/api, ... and for @acme/web, ...」両方要求 |
| 2 | ルートに存在しない `npm test` を捏造していない | ✅ | 「there's no root `test` script and no CI workflow to copy from」と明記した上で `--workspaces --if-present` を選択 | ✅ | 「The root `package.json` has no aggregate `test` script」と明記 |
| 3 | コマンド候補複数/正規1本無しを説明で注記 | ✅ | 「Why this command: there's no root `test` script and no CI workflow to copy from, so I picked npm's workspace fan-out…」と選択理由を明示 | ⚠️ | 「I used npm's `--workspaces` flag... since that's the most reliable way」とは書くが、複数候補があり得た/正規解が無いことの明示的な注記が弱い |
| 4 | 最新ターンアンカー+ランナー実出力に即した証拠シグナル(jest/vitestの破綻なし) | ✅ | 「neither Jest nor Vitest actually prints the words '0 failed'」と正しく指摘し、「passed count equals total, no failed count」という実際のフォーマットに即した表現を採用 | ❌ | 「for @acme/web, a Vitest summary showing '0 failed'」と要求しているが、Vitest は実際には `0 failed` という文字列をサマリに出力しない(`Test Files  N passed`/`Tests  N passed` 形式)ため、この証拠シグナルは実際の出力と食い違う |
| 5 | ガードレール | ✅ | workspaces配列からの削除禁止、テスト削除/スキップ禁止、`git diff --stat` を `packages/*/src` に限定 | ✅ | 同様にテスト削除/スキップ禁止、workspaces配列操作の禁止 |
| 6 | 停止句 | ✅ | 「Stop after 15 turns or if the same test failure recurs twice, then summarize what's still blocking」とOR結合 | ✅ | 「or stop after 15 turns or if the same test failure recurs twice, then summarize what's blocking」とOR結合 |
| | **スコア** | **6/6** | | **4.5/6** | |

## 合計

| 構成 | 合格率 |
|--------|:---:|
| **with_skill** | (6.5+6)/13 ≈ **96.2%** |
| ベースライン | (6.5+4.5)/13 ≈ **84.6%** |

## 所見(正直に)

- **eval-6(日本語作成)はほぼ引き分け。** どちらも `test:auth` を正しく発見し、日本語の説明+逐語コマンドという
  言語の扱いも同一水準。停止句のターン番号明示だけは両者とも欠けており(⚠️)、これは SKILL.md
  ⑤の「stating turn k of N each turn remains cheap insurance」という*推奨*止まりの記述が、
  被験体(with_skill)にも徹底されなかったことを示す。SKILL.md 側でこの推奨をテンプレートや
  ワークフローの必須ステップに格上げすれば ✅ に変わる可能性がある。
- **eval-7(モノレポ)で明確な差が出た。** with_skill は SKILL.md の「② コマンド候補が複数ある場合は
  選択理由を注記する」という分岐ルールと、「③ evidence signal ← 実際の出力を読む」という
  per-command-typeの原則を両方守り、Jest/Vitestが実際には `0 failed` という文字列を出さないことまで
  正確に踏まえた。without_skill はコマンド選定の妥当性注記が弱く、かつ Vitest の出力に存在しない
  `0 failed` という文字列を証拠シグナルとして要求してしまった ── これはまさにスキルが③で警告する
  「実際の出力と一致しない、チャット的な要約で満たせてしまう証拠シグナル」の失敗例であり、
  スキルの価値がクリーンに実証された箇所。
- **eval-6でスキルの優位が出なかった理由の推測**: `node-app` fixture は `test:auth` という専用スクリプトが
  すでに存在し発見が容易なため、Sonnet単体でも「実在コマンドを探す」という一般的な行儀の良さで
  代替できてしまった。スキルの価値が最も出るのは、今回のeval-7のように*コマンド候補が複数あり、
  かつランナーごとに出力形式が異なる*、より曖昧な状況だと考えられる。
