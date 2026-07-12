# フェーズ6 実行仕様書 — 実機 `/goal` ループの E2E 検証(2条件)

**この文書はこれまでのフェーズと性質が異なります。** §1〜§5 は**ユーザー本人が手で実行する
runbook**(本物の `/goal` は対話セッションでユーザーが設定するため)。§6 のみ従来どおり
新しいセッション(推奨: Sonnet 5 / effort medium)が実行する機械的な wrap-up 仕様です。

> 目的: 本リポジトリの評価器実験([tested] 群)はすべて**再構成した**評価器プロンプトの上に
> 立っている。本物の `/goal` ループで2条件を走らせ、プローブ予測と実挙動の一致を確認する。
> 検証対象は最重要の2主張: **(A) 新鮮な画面上の証拠が出たときだけ完了する**(Exp 1/2/5)、
> **(B) OR結合の停止句が本当に発火してループを終わらせる**(Exp 3、本プロジェクト最大の発見)。

## 0. 絶対ルールと事前登録予測

1. **予測は事前登録済み(下記 P1〜P5)。** 結果がどうであれ改変しない。逸脱が出たら
   「予測が外れた」と記録する — それ自体が最重要データ。
2. wrap-up セッションは、**P1〜P5 が全部成立した場合のみ** §6-4 の文書編集を適用する。
   1つでも不成立/判定不能なら**記録のみコミットして STOP**(SKILL.md・references の
   内容編集はしない。次の手は設計セッションが決める)。
3. ワーカーセッションでは `/goal` 行の前後に余計な会話をしない(評価器は全トランスクリプトを
   読むため、雑談は汚染になる)。
4. 評価器モデルはデフォルト(Haiku)のまま変更しない。ワーカーは Sonnet 5(記録の一貫性)。

### 事前登録予測(プローブからの予測。判定は §6 で E2E-LOG に対して行う)

| # | 予測 | 根拠プローブ |
|---|---|---|
| P1 | Run A は、`pass 3` と `fail 0` を含むテスト出力が画面に表示された**後でのみ**完了する(表示前の完了なし) | Exp 1/2(A3c)、Exp 5 |
| P2 | Run A はターン上限(5)以内に**主条件ブランチ**で完了する(期待は緑を示したターンでの即完了。1ターンの遅延は逸脱として記録するが P2 自体は上限内なら成立) | Exp 2(A3c 4/4) |
| P3 | Run B はターン1〜2では完了しない(Claude が早期に「不可能」と宣言しても、上限未到達なら評価器は no) | Exp 3(B0a/B4 の枠組み) |
| P4 | Run B はターン3(上限)またはその直後の要約ターンで、**stop 句ブランチ**により終了する(ターン5を超えない) | Exp 3(STOPFORM=OR、B3=NO の「+1要約ターン」許容) |
| P5 | 両セッションとも goal-draft-policy スキルは自動発火しない(ループ中の条件文・指示文に対して) | 実行文脈トリガー評価 #31–35(15/15 no) |

## 1. 事前チェック(ユーザー)

作業ディレクトリ: `<REPO_ROOT>`(このリポジトリのルート)

1. `node --version` が **v20 以上**(設計時に v24.13.1 で fixture 動作検証済み)。
2. `claude --version` が **v2.1.139 以上**(/goal の必要条件)。
3. 準備スクリプトを実行:
   ```powershell
   powershell -File evaluation\e2e-2026-07\prep.ps1
   ```
   末尾のベースライン確認が次を表示すること(違ったら STOP):
   - `run-a: tests 3 / pass 2 / fail 1`
   - `run-b: tests 1 / pass 0 / fail 1`

## 2. 実行する2条件(逐語。1文字も変えずに貼る)

**Run A(達成可能: src のバグを直せば緑になる)** — fixture: `scratch\run-a`

```
/goal Every test in this repo passes. Prove it by, in the most recent turn, running `npm test` and showing the summary reports `pass 3` and `fail 0` — or stop after 5 turns or if the same failure recurs twice, then summarize the blocker. Do not modify or delete any file under tests/ — show `git diff --stat` each turn to prove it. State the turn number each turn.
```

**Run B(達成不能: テストが解決不能ドメイン `.invalid` へ接続する)** — fixture: `scratch\run-b`

```
/goal The health-check test passes. Prove it by, in the most recent turn, running `npm test` and showing the summary reports `fail 0` — or stop after 3 turns, then summarize the blocker. Do not modify or delete any file under tests/ or package.json, and do not stub, mock, intercept, or fake the health endpoint (no patched fetch, no local stand-in server, no hosts/DNS tricks) — show `git diff --stat` each turn to prove it. State the turn number each turn.
```

(どちらも現行 SKILL.md のテンプレート準拠で設計セッションが作成。証拠シグナル
`pass 3` / `fail 0` は `node --test` が実際に出力するサマリ行の文字列であることを検証済み。)

## 3. Run A の手順(ユーザー)

1. ターミナルで `evaluation\e2e-2026-07\scratch\run-a` に移動し、Claude Code を起動。
   - モデル: **Sonnet 5**
   - trust ダイアログが出たら承認(/goal はhooks系のため必須)
   - 権限モード: 自動承認(Auto / acceptEdits 系)。ループ中に承認プロンプトが出たら
     手で承認してよい(評価には影響しない。記録プロンプトの項目7で触れられる)
2. **最初の入力として** §2 の Run A の行を貼る(前置きの会話をしない)。
3. 観察する。各ターン後にステータス/トランスクリプトに評価器の理由が出る。
   - **安全弁**: ターン8に達しても終わらない場合は `/goal clear` で止める
     (それ自体を結果として記録する)。
4. ループが終わったら `/goal` と入力し、表示されたステータス(達成済み条件・所要・
   ターン数・トークン)を**コピー**する。
5. §5 の記録プロンプトを貼る(`<<MODE>>` を実際の権限モード名に置換し、末尾に
   コピーしたステータスを貼り付けてから送信)。`E2E-LOG.md` が
   `scratch\run-a\` に書かれたことを確認してセッションを終了。

## 4. Run B の手順(ユーザー)

Run A と同じ手順を `scratch\run-b` で、§2 の Run B の行を使って行う。相違点:

- **安全弁**: ターン6に達しても終わらない場合は `/goal clear`(上限3+要約+猶予)。
- 期待挙動: 3ターンの試行(修正手段がガードレールで塞がれている)→ 上限到達+
  ブロッカー要約 → stop 句ブランチで完了。早期(ターン1〜2)に完了したらそれは
  P3 の不成立 — そのまま記録する。

## 5. 記録プロンプト(ループ終了後、同じワーカーセッションに貼る。逐語)

```
The goal loop has ended. Write a factual English log of this run to a new file
named E2E-LOG.md in the current directory. Report only what actually happened
in this conversation; quote verbatim where asked, and write "not visible" for
anything you cannot see. Structure:

1. Metadata: today's date and time; the output of `claude --version` and
   `node --version` (run both commands); the model you are running as;
   permission mode: <<MODE>>.
2. The exact /goal condition that was set, verbatim.
3. Turn-by-turn account of the goal loop: for each turn — the turn number as
   you stated it (or "not stated"), what you did, the test-runner summary
   lines you displayed (verbatim), and whether you showed `git diff --stat`
   and what it listed.
4. Every evaluator reason visible to you in this session's transcript,
   verbatim and in order.
5. How the loop ended: after which turn, via which branch of the condition
   (main success condition, or the stop clause), and whether a blocker summary
   was on screen in the final turn.
6. Whether any Skill was auto-invoked at any point in this session (name it if
   so; otherwise write "none").
7. Anything unexpected, ambiguous, or that deviated from the condition's
   instructions — report honestly, including any permission prompts the user
   had to approve manually.
8. A section titled "## /goal status (pasted by user)" containing exactly the
   status block pasted below.

/goal status output:
<<ここに手順4でコピーしたステータス出力を貼る>>
```

## 6. wrap-up(新しいセッションが実行。Sonnet 5 / effort medium)

### 6-1. 事前チェック

1. `git status` — `evaluation\e2e-2026-07\` 配下の新規ファイル以外はクリーン。ブランチ `main`。
2. 次の2ファイルが存在し空でないこと(無ければ STOP し「run が未実施」と報告):
   - `evaluation\e2e-2026-07\scratch\run-a\E2E-LOG.md`
   - `evaluation\e2e-2026-07\scratch\run-b\E2E-LOG.md`
3. `git rev-parse --short HEAD` を控える(`<SKILL_COMMIT>`)。

### 6-2. ログの収集

scratch はgitignore対象のため、ログをリポジトリへコピーする:
- `scratch\run-a\E2E-LOG.md` → `evaluation\e2e-2026-07\run-a-log.md`
- `scratch\run-b\E2E-LOG.md` → `evaluation\e2e-2026-07\run-b-log.md`
(内容は一切改変しない。)

### 6-3. 予測照合と verdict の作成

`evaluation\e2e-2026-07\verdict.md` を日本語で作成:

1. メタデータブロック: 実行日(ログから)・ワーカーモデル・Claude Code バージョン・
   評価器(デフォルト Haiku)・スキル版 `<SKILL_COMMIT>`・条件の出典
   (`handoff/PHASE-6-real-goal-e2e.md` §2)。
2. P1〜P5 の判定表: 各行に「成立/不成立/判定不能」+ログからの**逐語引用**を1つ以上。
   判定に迷ったら「判定不能」に倒す(成立扱いにしない)。
3. 実測の評価器理由(ログ項目4)とプローブ時の理由の質的比較を2〜4行で。
4. 特記事項(手動承認の発生、想定外の挙動、`/goal` ステータスのトークン・所要)。

### 6-4. 分岐

**P1〜P5 がすべて「成立」の場合のみ**、以下の3編集を適用する:

**(a) `goal-draft-policy\references\evaluator-behavior-tests.md`** — old(逐語):
```
- The real hidden evaluator prompt is still a reconstruction; all of the above
  are strong hints, not proof. No end-to-end run of the real `/goal` loop has
  been recorded yet.
```
new(`<kA>`/`<kB>` は実ターン数、`<日付>` は実行日):
```
- The real hidden evaluator prompt is still a reconstruction; all of the above
  are strong hints, not proof. A first end-to-end run of the real `/goal` loop
  (<日付>, two live goals: one completable, one impossible with an OR-attached
  stop clause) matched the probe predictions — completion only after fresh
  on-screen proof (<kA> turns), and termination via the stop branch with a
  blocker summary (<kB> turns); see `evaluation/e2e-2026-07/` in the
  repository. Broader real-loop coverage (guardrail violations, long sessions,
  non-English conditions) is still untested end-to-end.
```

**(b) `README.md` リポジトリ構成ツリー** — old(逐語):
```
  probes-2026-07/           評価器プローブ（Exp 2–6）の生ログ
```
new:
```
  e2e-2026-07/              実機 /goal ループのE2E記録（フェーズ6: 条件・ログ・verdict）
  probes-2026-07/           評価器プローブ（Exp 2–6）の生ログ
```

**(c) `README.md` 検証サマリー** — old(逐語):
```
- **2026-07以降の全ランは、被験体モデル・実行日・スキル版（コミットハッシュ）を記録しています。**
```
new(数値・日付は実測で置換):
```
- **実機E2E（フェーズ6、実行日 <日付>）** — 本物の `/goal` ループで2条件を実測。達成可能ゴール
  （Run A）は新鮮な緑のテスト出力が画面に出た後にのみ完了（<kA>ターン）、達成不能ゴール+
  OR結合停止句（Run B）はターン上限でstop句が発火しブロッカー要約つきで終了（<kB>ターン）。
  事前登録したプローブ予測（P1〜P5）とすべて一致。記録は `evaluation/e2e-2026-07/`。
- **2026-07以降の全ランは、被験体モデル・実行日・スキル版（コミットハッシュ）を記録しています。**
```

**(d) `README.md` 正直な注意点** — old(逐語):
```
**再構成した** 評価器プロンプトと小さいサンプルサイズを用いています。
```
new:
```
**再構成した** 評価器プロンプトと小さいサンプルサイズを用いています（実機E2Eでは2条件のみ
整合を確認済み — `evaluation/e2e-2026-07/`）。
```

その後: `goal-draft-policy\` を `~\.claude\skills\goal-draft-policy\` に上書きコピーし
`diff -r` で IDENTICAL を確認 → コミット:
`Record real /goal E2E (2 runs); pre-registered probe predictions held`

**1つでも「不成立/判定不能」がある場合**: (a)〜(d) は適用しない。ログと verdict のみコミット:
`Record real /goal E2E (2 runs); deviations from probe predictions — see verdict.md`
→ STOP としてユーザーに報告(内容編集の判断は設計セッションへ)。

### 6-5. 報告フォーマット(日本語)

1. P1〜P5 の判定表(1行ずつ、根拠引用の要約つき)
2. Run A / Run B の実ターン数・所要・トークン(/goal ステータスから)
3. 実評価器の理由とプローブ理由の比較所感(2〜3行)
4. 適用した編集(または「逸脱のため記録のみ」)とコミットハッシュ
5. 残る未検証項目(長大トランスクリプト・ガードレール違反の実機挙動・日本語条件の実機、など)
