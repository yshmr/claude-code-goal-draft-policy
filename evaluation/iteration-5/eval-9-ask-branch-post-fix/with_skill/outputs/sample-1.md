`/goal` を組む前に一点だけ確認させてください。

「エンジニアじゃないメンバーが読んでも分かる」は、このままだと `/goal` の完了条件にできません。`/goal` の判定役(Haiku)は会話の中に書かれた内容だけを見て yes/no を判断します(ツールは実行できません)。なので「読んで分かる」のような主観的な基準は、いつまで経っても yes/no が決められず、Claude が自走を続けても終わらないか、逆に Claude が「もう分かりやすくなりました」と言い張るだけで(実際は変わっていなくても)終わってしまう、のどちらかになりがちです。

実際に今の README を見ると、この主観性は仮の話ではなく具体的に効いてきます:

```
# svc-gateway
Edge ingress for the acme mesh. mTLS termination via envoy sidecar, JWT claims
propagation (RFC 7519), circuit-breaking per upstream SLO budget.
...
helm install w/ values-prod.yaml (see infra repo), then port-forward 8443 and
curl /healthz with the platform bearer. If 503, check the OPA bundle rev.
...
ENV: GW_UPSTREAM_TIMEOUT_MS, GW_RETRY_BUDGET, GW_JWT_AUD (comma-sep), GW_OTEL_EP.
```

mTLS、envoy sidecar、OPA bundle rev、retry budget といった専門用語が並んでいて、「非エンジニアにも分かる」を達成する方法はいくらでもあります(用語集を足す/全部言い換える/図解を足す/対象読者を絞る、等)。どれで「完了」とするかは、Claude が判定モデルに証拠として見せられる形で決めておかないと、goal 自体が機能しません。

以下のどれか(または別の基準)を教えてください。決まり次第、条件を書いて `/goal` としてお渡しします。

1. **専門用語ゼロ方式**: README 中に業界特有の略語・専門用語(例: mTLS, JWT, OPA, SLO, envoy 等の一覧をあらかじめ列挙)が一切残っていないこと。`grep` で該当語を数えて 0 件になったことを毎ターン証拠として出す。
2. **必須セクション方式**: 「このサービスは何をするものか」「困ったときにどうするか」など、非エンジニアが最低限読める平易な項目立て(見出しリスト)を先に決めて、そのセクションが全部揃っていることを毎ターン確認する。
3. **第三者レビュー方式**: 書き直した README を Claude 自身に「非エンジニアの視点でレビューする」役割で読み直させ、指摘したチェックリスト項目(例: 専門用語に平易な説明が付いているか、手順が番号付きで書かれているか、など)が全て解消されていることを示す。

1 が一番機械的に判定しやすく、自走ループが素直に終わりやすいのでおすすめですが、「用語を消す」より「説明を足す」方を重視したいなら 2 か 3 が合うと思います。どれにしますか。
