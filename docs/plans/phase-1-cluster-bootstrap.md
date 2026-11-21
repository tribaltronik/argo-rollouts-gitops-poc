# Phase 1 — Cluster Bootstrap

**Milestone:** M1 — Cluster bootstrap (`docs/spec.md` §10)
**Goal:** kind cluster with 1 control-plane + 2 workers comes up via a single reproducible command and tears down cleanly.

## Tasks

### T0.1 — Pin and install required tooling versions
- **Objective:** Ensure tooling meets the spec §9 baseline (kind v0.23.0+, kubectl v1.29+, Helm v3.14+, Argo CD v2.11+, Argo Rollouts v1.7+, NGINX Ingress v1.10+, kubectl-argo-rollouts v1.7+).
- **Validation:** Version checks via CLI for each tool.
- **Maps to:** SC1, SC2, SC9.

### T1.1 — Create kind cluster configuration
- **Objective:** Author `kind/cluster.yaml` — 1 control-plane + 2 workers, port mappings for NGINX (80/8080) and Argo CD (8080).
- **Validation:** `kind create cluster -c kind/cluster.yaml` succeeds; `kubectl get nodes` shows 3 nodes `Ready`.

### T1.2 — Add Makefile lifecycle targets
- **Objective:** Add `make up`, `make down`, `make status`, `make sync`.
- **Validation:** All targets execute successfully.

### T1.3 — Bootstrap cluster via single command
- **Objective:** Run `make up` on a clean machine; no hidden manual steps.
- **Validation:** **SC1** — clean execution; `kubectl get nodes` → 3× `Ready`.

## Exit criteria
- SC1 (reproducible `make up`) and SC10 (clean teardown path) satisfied at this level.
