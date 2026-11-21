# Phase 3 — Initial App Deploy

**Milestone:** M3 — Initial app deploy (`docs/spec.md` §10)
**Goal:** Git repo contains demo Rollout (Canary, v1, 20→50→100) and Argo CD syncs it → Rollout `Healthy`, 100% traffic.

## Tasks

### T3.1 — Author demo application manifests
- **Objective:** Create `apps/demo/` — `rollout.yaml`, `services.yaml`, `ingress.yaml` (NGINX canary annotations), `analysis-template.yaml`, `kustomization.yaml`.
- **Validation:** `kubectl kustomize apps/demo` renders without errors.

### T3.2 — Author Argo CD Application
- **Objective:** Create Argo CD `Application` pointing at the Git repo/path containing the demo manifests.
- **Validation:** `argocd app create ... --dry-run` renders a valid manifest.

### T3.3 — Git commit → Argo CD sync → Rollout Healthy (v1, 100%)
- **Objective:** Commit manifests; Argo CD detects drift and syncs; confirm Rollout v1 reaches `Healthy`.
- **Validation:** **SC3** — `argocd app get demo` → `Synced` + `Healthy`; Rollout `Healthy`, current version v1, 1/1 ready replicas.

## Exit criteria
- SC3 satisfied; SC8 initiated correctly — initial state deployed purely via Git.
