# Phase 2 — Platform Install

**Milestone:** M2 — Platform install (`docs/spec.md` §10)
**Goal:** Argo CD, Argo Rollouts, and NGINX Ingress Controller installed via Helm and healthy.

## Tasks

### T2.1 — Install Argo CD via Helm
- **Objective:** Install Argo CD chart into `argocd` namespace.
- **Validation:** Argo CD control-plane pods `Running/Ready`.

### T2.2 — Install Argo Rollouts via Helm
- **Objective:** Install Argo Rollouts chart into `argo-rollouts` namespace.
- **Validation:** Argo Rollouts controller pod `Running/Ready`.

### T2.3 — Install NGINX Ingress Controller via Helm
- **Objective:** Install ingress-nginx chart; create `Ingress` with `nginx` class.
- **Validation:** Ingress controller pod `Running/Ready`.

### T2.4 — Verify platform health
- **Objective:** Confirm Argo CD + Argo Rollouts + NGINX pods all `Running/Ready` cluster-wide.
- **Validation:** **SC2** — `kubectl get pods -A` shows all platform pods `Running`/`Ready`.

## Exit criteria
- SC2 satisfied — platform installed and healthy.
