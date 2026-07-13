# Future work / 未検証項目・ロードマップ

このリポジトリで **まだ確定していないこと** と **これからやること** を一か所に
集約する。外部からの指摘の受け皿でもある（末尾「External feedback」節）。

> **スコープの線引き**
> - このファイル = *open / unverified items + roadmap*（これからの話）。
> - **現状**どの評価が正典かの索引 → [`../evaluation/README.md`](../evaluation/README.md)（"future" ではないので分離）。
> - **(a) Runtime safety guidance**（`/goal` ループの自律実行に伴う注意）→ `README.md` / `SKILL.md` の「安全な使い方」側。ここには書かない。
> - **(b) Repository publication safety**（公開前の混入検査）→ [`publication-safety.md`](publication-safety.md) と `scripts/check-publication-safety.sh`。CI 化はこのファイルのロードマップ項目。

## 1. 既知の限界 / 未検証（Known limitations）

README「検証サマリー（と正直な注意点）」の未確定事項をここに集約する。数値は
**強い示唆であって保証ではない**。

| # | 限界 | 現状 | 影響 |
|---|------|------|------|
| L1 | トリガー検証は実 `available_skills` 発火機構の **近似** | 判定者モデルに説明文を読ませる再構成。実機の発火は未検証 | description の実発火精度は推定値 |
| L2 | 評価器プローブは **再構成した評価器プロンプト＋小サンプル** | Exp 2–6、各 n=4 前後 | `[tested]` は「強い示唆」であり公式挙動の証明ではない |
| L3 | 実機 `/goal` E2E は **2条件のみ** | フェーズ6（`evaluation/e2e-2026-07/`）で達成可能/不能の2本 | 実評価器との整合は限定的なサンプルで確認 |
| L4 | 2026-07 の判定者＝被験体がいずれも **claude-sonnet-5**（同一性） | 独立性が無い | バイアスの可能性。judge≠subject 未実施 |
| L5 | モデル未記録の旧イテレーション（iteration-1・iteration-2 初回・初回トリガー） | 被験体モデル不明 | 2026-07 の数値と **直接比較不可** |
| L6 | iteration-4 は各セル **n=1** の単発ラン | eval-9 では with_skill が実際に敗北（修正前） | スキル優位は保証ではなく傾向 |
| L7 | 実機で **未検証の挙動** — 長大 session・ガードレール違反・日本語条件の実 `/goal` 挙動 | E2E は達成可能/不能の2条件のみ（`evaluation/e2e-2026-07/`） | これらは新しい成功 claim に昇格しない |
| L8 | **production reliability / 一般化** は未実証 | fixture・小サンプルでの示唆のみ | 「本番で動く」保証はしない |

詳細な数値と文脈は README として残し、ここは索引に留める（二重管理を避ける）。
**これらの制約は現時点の境界であり、新しい成功 claim へ昇格させない**（外部指摘 F6）。

## 2. ロードマップ（Planned work）

| # | 項目 | 状態 | メモ |
|---|------|------|------|
| R1 | 公開前スキャナを **CI（GitHub Actions）** で自動実行 | 予定 | push/PR で `scripts/check-publication-safety.sh` を回す。本タスクの次段で着手 |
| R2 | `skill-creator` 最適化ループの **Windows 移植性バグ** 対応 | ブロック中 | サブプロセスのパイプに対する `select.select()` が Windows で不可。Linux で回すか、パッチするか要判断 |
| R3 | サンプルサイズ拡大 / **judge ≠ subject** の独立評価 | 未着手 | L2・L4 の緩和 |
| R4 | 実機 E2E の **条件数を拡張**（現状2条件） | 未着手 | L3 の緩和。checklist 型・時間上限型など |
| R5 | 実 `available_skills` 発火機構での **トリガー再検証** | 未着手 | L1 の緩和 |
| R6 | publication-safety の **synthetic UUID allowlist** を用意し CI を `--strict` 化 | ✅ 完了 | `.publication-safety-allowlist`（未許可 UUID は `--strict` で fail、synthetic は明示許可）。CI は `--strict` 実行 |
| R7a | evaluation artifact の **必須項目チェック**（新 run のモデル・実行日・skill commit） | ✅ 完了 | `scripts/check-eval-artifacts.sh`。2026-07+ の8記録の provenance を検証（legacy は対象外） |
| R7b | fixture↔result の **hash 整合**（記録後に fixture が改変されていないこと） | ✅ 完了 | `scripts/check-fixture-integrity.sh` ＋ `evaluation/fixtures.manifest.sha256`（git blob ハッシュで正規化＝クロスプラットフォーム安全）。33 fixture を固定、staged/commit 済み改変を検知 |
| R8 | synthetic data boundary の **明示チェック** | ✅ 完了 | `evaluation/README.md` に SYNTHETIC-DATA-DECLARATION を必須化（`check-eval-artifacts.sh` が存在検査）。内容漏洩は publication-safety が別途遮断 |

**実行種別の分離（外部指摘 F2）**: R1 は *documentation/CI だけで完結*（provider 不要、通常 push で回せる）。R2–R5 は **provider / Claude Code / 実 `/goal` / 課金評価**を伴うため、pure CI から切り離し、承認済みの評価 contract がある場合のみ manual workflow として実施する（既存結果の rerun・置換としては扱わない — 外部指摘 Phase C）。

## 3. 指摘の入れ方（How to file feedback）

外部からの指摘は次のいずれかで:

- **GitHub Issues** — バグ・限界・改善提案。再現手順や該当ファイルパスを添えると助かる。
- **このファイルの「External feedback」節に追記**する PR — 下のテンプレに沿って1件1エントリ。

対応済みの指摘は状態を `resolved` にし、対応内容（コミット/PR）へのリンクを残す。

## 4. External feedback（外部からの指摘ログ）

各エントリは以下の形式:

```
### F<n>: <一行タイトル>
- **出所**: <誰／どこから>（Issue #, PR #, 直接連絡 など）
- **受領日**: YYYY-MM-DD
- **指摘内容**: <要約>
- **対象**: <該当ファイル/カテゴリ、L#/R# との対応>
- **状態**: open | in-progress | resolved | wontfix
- **対応**: <対応内容＋コミット/PR リンク。未対応なら空>
```

<!-- 新しい指摘はこの下に追記していく -->

### F1: canonical な future-work がない
- **出所**: 外部レビュー（対象 repo: `github.com/yshmr/claude-code-goal-draft-policy`）
- **受領日**: 2026-07-13
- **指摘内容**: 改善事項が handoff・verdict・benchmark・README に分散。`docs/future-work.md` 相当の canonical 一覧が無い。完了/未検証の分離、各項目への authority リンク、provider 必要項目と doc/CI 完結項目の分離、handoff は参照元扱いを推奨。
- **対象**: このファイル全体、R1–R5 の実行種別分離
- **状態**: resolved
- **対応**: `docs/future-work.md` 新設（本ファイル）。既知の限界 L1–L8 と ロードマップ R1–R5 を分離、provider/doc の実行種別を明記、handoff は参照リンクとして扱う。

### F2: GitHub Actions による pure validation が無い
- **出所**: 同上
- **受領日**: 2026-07-13
- **指摘内容**: 第三者が公開 repo 上で確認できる自動検証が無い。推奨する pure CI = Markdown 相対リンク存在確認 / Skill frontmatter・metadata 検証 / evaluation artifact 必須項目 / fixture↔result hash 整合 / synthetic 境界 / publication safety scan。provider・実 `/goal`・課金評価は通常 push で走らせず manual workflow に分離。
- **対象**: R1、R6、R7a/R7b、R8、Phase B
- **状態**: resolved
- **対応**: pure validator 5種を実装 — `check-publication-safety.sh`（`--strict` ＋ `.publication-safety-allowlist`）/ `check-markdown-links.sh` / `check-skill-metadata.sh` / `check-eval-artifacts.sh` / `check-fixture-integrity.sh`。`.github/workflows/validate.yml`（push/PR、provider なし）で実行、provider/評価は `.github/workflows/manual-empirical.yml`（workflow_dispatch のみ）へ分離。**レビュー推奨の pure CI 6項目すべて実装** — Markdown リンク・skill frontmatter/metadata・evaluation artifact 必須項目・fixture↔result hash 整合・synthetic 境界・publication safety scan。

### F3: public-safety の意味（runtime とは別）
- **出所**: 同上
- **受領日**: 2026-07-13
- **指摘内容**: ここでの public-safety は **repository publication safety**。runtime safety（bypass permissions・最小権限・sandbox/allowlist・停止句・user-owned launch）とは別項目で、後者は SKILL/README の「安全な使い方」へ。用語は `Runtime safety guidance` / `Repository publication safety` を推奨。
- **対象**: `docs/publication-safety.md`、本ファイル冒頭のスコープ線引き
- **状態**: resolved
- **対応**: `docs/publication-safety.md`（(b)）を新設し、冒頭で (a)runtime / (b)publication を明示分離。用語も採用済み。runtime safety は本ファイルに混ぜていない。

### F4: historical result と current authority の分離
- **出所**: 同上
- **受領日**: 2026-07-13
- **指摘内容**: README で旧評価「100% vs 58%」が目立つ一方、最新のモデル記録付き再評価は「85% vs 83%」で拮抗。短時間レビューで誤解の恐れ。current authority を明示し historical を分離（削除・再採点・置換はしない、異なるモデル/条件を直接比較しない、Skill 優位を保証しない境界を維持）。
- **対象**: `README.md`、`evaluation/README.md`
- **状態**: resolved
- **対応**: README「検証サマリー」冒頭に current(85/83) / historical(100/58) を区別する callout を追加し、`evaluation/README.md` へ導線を張った。旧結果は削除・再採点せず保持。

### F5: final authority への導線を一本化
- **出所**: 同上
- **受領日**: 2026-07-13
- **指摘内容**: 第三者が「最終的にどれを読めばよいか」判断しにくい。`evaluation/authority-index.md` 等の索引を作り current/historical/contaminated/E2E authority を分類、README から canonical へ直接リンク、failure/deviation を passing rerun で上書きしない。
- **対象**: `evaluation/README.md`、`README.md`
- **状態**: resolved
- **対応**: `evaluation/README.md` を authority 索引として新設（current/historical/contaminated/E2E を分類、置換関係とケース単位の「今どれを読むべきか」を掲載）。README のリポジトリ構成と検証サマリー callout から直接リンクを追加。failure/deviation は passing rerun で上書きしていない。

### F6: 現在の未実証範囲を維持する
- **出所**: 同上
- **受領日**: 2026-07-13
- **指摘内容**: trigger は実発火機構の近似 / 一部で判定者＝被験体が同一 claude-sonnet-5 / 一部 n=1 / E2E は2条件 / 長大 session・ガードレール違反・日本語条件の実機挙動は未検証 / production reliability・一般化は未実証。これらを新しい成功 claim へ昇格しない。
- **対象**: L1–L8
- **状態**: resolved
- **対応**: 既知の限界 L1–L8 として明記（L7 に実機未検証挙動、L8 に production/一般化未実証を追加）。「新しい成功 claim へ昇格させない」を明記。
