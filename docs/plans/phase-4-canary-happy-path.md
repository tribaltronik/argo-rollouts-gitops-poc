# Phase 4 — Canary Happy Path

**Milestone:** M4 — Canary happy path (`docs/spec.md` §10)
**Goal:** v2 canary progresses 20% → 50% → 100%, analysis passes, traffic split between v1 and v2 verifiable.

## Tasks

### T4.1 — Change image tag v1 → v2 in Git
- **Objective:** Commit a change bumping the demo app image tag from `v1` to `v2`.
- **Validation:** `git diff` shows only the intended image tag change.

### T4.2 — Argo CD detects drift and syncs (GitOps flow)
- **Objective:** Allow Argo CD auto-sync (or run `make sync`).
- **Validation:** No manual `kubectl` rollout changes performed.

### T4.3 — Canary step 1: `setWeight: 20`, pause
- **Objective:** Observe Argo Rollouts pause at 20% via Ingress canary annotations.
- **Validation:** Rollout status shows weight `20`.

### T4.4 — Run AnalysisTemplate; on `Successful` advance to 50%
- **Objective:** Run/let the analysis; confirm result drives progression.
- **Validation:** **SC6** — AnalysisRun shows `Successful` in healthy scenario; Rollout advances to weight `50`.

### T4.5 — Advance to `setWeight: 100`; promotion complete
- **Objective:** Confirm promotion to 100% — v2 now serves all traffic.
- **Validation:** **SC4** — Rollout shows promoted version v2, `Healthy`.

### T4.6 — Verify traffic split mix (v1 ↔ v2)
- **Objective:** Send traffic to the NGINX Ingress during a paused canary and verify mixed responses per weight.
- **Validation:** **SC5** — `curl` to ingress returns mix of v1/v2 responses according to current weight.

## Exit criteria
- SC4, SC5, SC6, SC8 satisfied — canary happy path complete.
