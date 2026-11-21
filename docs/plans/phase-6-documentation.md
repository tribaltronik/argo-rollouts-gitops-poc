# Phase 6 — Documentation and Definition of Done

**Milestone:** M6 — Documentation (`docs/spec.md` §10)
**Goal:** README reproducible on a clean machine; full DoD met.

## Tasks

### T6.1 — Write reproducible README
- **Objective:** Document `make up` / install / sync / status / down flow plus acceptance evidence capture.
- **Validation:** **SC9** — clean-machine reproduction results in criteria 1–8 passing.

### T6.2 — Capture acceptance evidence
- **Objective:** Record in README:
  - `kubectl get pods -A` output after bootstrap (SC2)
  - `argocd app get demo` → `Synced` + `Healthy` (SC3)
  - `kubectl argo rollouts get rollout demo` during canary (SC4)
  - Post-rollback rollout output (SC7)
  - Terminal capture of mixed v1/v2 responses (SC5)
  - `make down` output confirming clean teardown (SC10)

### T6.3 — Write future EKS migration document
- **Objective:** Attach migration notes: NGINX Ingress → AWS Load Balancer Controller, `nginx.ingress.kubernetes.io/canary*` → `alb.ingress.kubernetes.io/*`, ECR image refs, IRSA, in-cluster → Amazon Managed Prometheus, kind → EKS provisioning.
- **Validation:** Migration doc accurately reflects spec §12 mapping.

### T6.4 — Final DoD verification
- **Objective:** Confirm all 10 success criteria met and recorded; `make up`/`make down` work on clean machine; EKS migration doc present.
- **Validation:** SC9, SC10 + DoD (§8) satisfied.

## Exit criteria
- DoD (`docs/spec.md` §8) fully met — all success criteria validated with evidence.
