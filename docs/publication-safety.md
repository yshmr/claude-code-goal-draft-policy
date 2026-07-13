# Repository publication safety（公開前チェックリスト）

このリポジトリを公開・更新して push する前に、**個人・ローカル・機微な情報が
混入していないこと**を確認する手順。`Anonymize example paths`（履歴書き換え）の
延長線上にある恒常的な運用ルール。

> スコープ注記: これは **(b) Repository publication safety** — 「何が repo に
> 入ってよいか」の検査。`/goal` ループが自律実行することに伴う **(a) Runtime
> safety guidance** とは別概念で、そちらは `README.md` / `SKILL.md` の「安全な
> 使い方」側に属する。混同しないこと。

## 1. 自動スキャンを先に走らせる

```bash
bash scripts/check-publication-safety.sh          # 通常
bash scripts/check-publication-safety.sh --strict # WARN も失敗扱いにする
```

- 追跡ファイル（`git ls-files`）のみを対象にするので、`node_modules/` や
  `scratch/` などの未追跡物は自動的に除外される。
- 終了コード `0` = 既知パターンに不一致 / `1` = FAIL あり（または `--strict`
  で WARN あり）。
- **緑は「既知パターンに当たらなかった」というだけで、安全の証明ではない。**
  下のチェックリストは引き続き人間が確認する。

スキャナが見るカテゴリ:

| 重大度 | カテゴリ |
|--------|----------|
| FAIL | 秘密情報（API キー・token・private key・`api_key=`/`secret=` 代入） |
| FAIL | ローカル絶対パス / ユーザー名（`C:\Users\…`, `C:/Users/…`, `/home/…`, `/Users/…`, `$USERPROFILE`） |
| FAIL | 個人メールアドレス（`noreply@` と `example.*` は除外） |
| FAIL | `.jsonl` / `.sqlite` / `.db` / `checkpoint` / `history` ファイルの追跡 |
| WARN | UUID（session/task/thread ID の疑い。synthetic なら可、要目視） |
| WARN | `session id:` / `task id:` などの ID フィールド |

## 2. 人間によるチェックリスト

自動スキャンでは拾いきれない、文脈依存の混入を目視で確認する。

- [ ] **秘密情報** — API キー、token、認証情報、`.env`、private key が無い。
- [ ] **ローカルパス / ユーザー名** — 絶対パスやホームディレクトリ、実ユーザー名が
      出力例・ログ・fixture に残っていない（例示は匿名化済みか）。
- [ ] **session / task / thread / conversation ID** — 実 ID は `<redacted>` 化。
      証拠価値のある値（timestamp・duration・token 数）は残してよい。
      → 実例: `evaluation/e2e-2026-07/run-a-log.md` / `run-b-log.md` の Session id。
- [ ] **checkpoint DB / ローカル履歴 / raw JSONL** — これらは追跡しない
      （`.gitignore` で遮断済み。意図せず `git add -f` していないか）。
- [ ] **個人情報・実業務データ** — 実在の人物・顧客・社内データが fixture や
      ログに入っていない。
- [ ] **synthetic であることの担保** — fixture・eval 出力・プローブログは
      合成データか再構成データであり、実運用のトランスクリプトそのものではない。
- [ ] **コミット履歴** — 上記が過去コミットに残っていないか（必要なら push 前に
      履歴書き換え。既に一度実施済み: `Anonymize example paths`）。
- [ ] **コミットフッタ** — `Co-Authored-By: … <noreply@anthropic.com>` は
      意図的な例外（スキャナも許可リスト済み）。

## 3. スキャナの限界（正直な注意点）

- 正規表現ヒューリスティックであり、**網羅の証明ではない**。新種の秘密情報
  形式や、文脈でしか判別できない個人情報は取りこぼしうる。
- 追跡ファイルのみを見る。**過去コミットの中身は見ない** — 履歴に混入した場合は
  別途 `git log -p` / `git grep <rev>` で確認する。
- git-bash（MSYS）は引数中のバックスラッシュを潰すため、Windows パス検知は
  リテラル `\` を避けて区切り文字クラスで表現している（`scripts/` 内コメント参照）。
  パターンを編集する際はこの制約に注意。

## 4. 新しいカテゴリを足したくなったら

`scripts/check-publication-safety.sh` の `scan FAIL …` / `scan WARN …` 行に
パターンを追加し、**必ず既知の悪例で検知することと、実リポジトリで誤検知しない
ことの両方**を確認してからコミットする（このスクリプト自体、そうやって
自己テストで検証した）。
