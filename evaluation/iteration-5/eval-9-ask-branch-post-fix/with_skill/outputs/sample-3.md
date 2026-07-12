リポジトリ（`docs-repo`、対象は `README.md`）を見ました。今の内容はこれです。

```md
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

`/goal` を組む前に一点確認させてください。

`/goal` の完了条件は、ツールを使わない小型モデル（評価者）が**会話の文字起こしだけ**を見て yes/no を判定する仕組みです。なので条件は「客観的に真偽が決まること」が必須で、"エンジニアじゃない人が読んで分かる" はそのままだと主観的すぎて、評価者がいつ「分かる」になったのか判定できず、ループが終わらないか、逆に生煮えの書き直しで「終わった」と誤判定される可能性があります。

なので、"分かる" を測れる基準に落とし込みたいです。候補を3つ考えました。どれか選ぶか、他の基準を教えてください（複数の組み合わせも可）。

1. **専門用語ゼロチェック**: `mTLS`, `JWT`, `sidecar`, `SLO`, `OPA`, `envoy`, `RFC`, `configmap`, `helm` などの禁止用語リストを決めて、README 内にそれらの語が**説明なしで**残っていないことを機械的に確認する（用語集セクションを作るか、初出時に平易な言い換えを併記すれば通過、というルール）。
2. **必須セクションの構造チェック**: 「このサービスは何をするか（一文で）」「なぜ必要か」「困ったときにどこに聞くか」など、非エンジニアが必要とする見出しが揃っているかをチェックリストで確認する。
3. **可読性スコア**: Flesch-Kincaid などの可読性スコアを計算するスクリプトを走らせ、しきい値（例: 学年レベル8以下）を下回ることを機械的に確認する。

どの基準で「非エンジニアにも分かる」を判定しますか。決まったら、その基準に沿って `/goal` の条件（終了状態・証拠コマンド・ガードレール・打ち切り条件）を組んで提示します。
