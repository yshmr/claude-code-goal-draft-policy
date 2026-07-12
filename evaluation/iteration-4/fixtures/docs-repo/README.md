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
