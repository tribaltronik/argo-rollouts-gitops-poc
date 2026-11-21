# Plan: POC — GitOps with Argo CD + Argo Rollouts on a local kind cluster

> **Source spec:** `docs/spec.md`
> **Status:** Draft plan decomposed into phase plans — see [Phase plans](#phase-plans)

---

## Purpose

Validate, in a **fully local and cloud-independent** way, the complete GitOps flow for progressive application deployment:

- **Argo CD** as the GitOps engine (declarative sync from Git)
- **Argo Rollouts** as the progressive deployment controller (Canary and/or Blue/Green)
- **kind** as the local Kubernetes cluster
- **NGINX Ingress Controller** as the traffic routing layer (replacing AWS ALB)

---

## Phase plans

| Phase | Milestone | Deliverable | Plan file |
|-------|-----------|-------------|-----------|
| Phase 1 | M1 | Cluster bootstrap | `docs/plans/phase-1-cluster-bootstrap.md` |
| Phase 2 | M2 | Platform install | `docs/plans/phase-2-platform-install.md` |
| Phase 3 | M3 | Initial app deploy | `docs/plans/phase-3-initial-app-deploy.md` |
| Phase 4 | M4 | Canary happy path | `docs/plans/phase-4-canary-happy-path.md` |
| Phase 5 | M5 | Rollback path | `docs/plans/phase-5-rollback.md` |
| Phase 6 | M6 | Documentation | `docs/plans/phase-6-documentation.md` |

---

## Milestones and exit criteria

| # | Milestone | Exit criteria (from phase plans) |
|---|-----------|--------------------------------|
| M1 | Cluster bootstrap | SC1 + SC10 satisfied (reproducible `make up`, clean teardown) |
| M2 | Platform install | SC2 satisfied (Argo CD, Argo Rollouts, NGINX healthy) |
| M3 | Initial app deploy | SC3 satisfied (Git → Argo CD sync → Rollout `Healthy`) |
| M4 | Canary happy path | SC4, SC5, SC6, SC8 satisfied (20% → 50% → 100%, split, analysis, GitOps) |
| M5 | Rollback path | SC7, SC8 satisfied (automatic rollback) |
| M6 | Documentation | SC9, SC10 + DoD satisfied (reproducible docs, teardown) |

---

## Task format

Each task in the phase plans follows this shape:

- **Objective** — single focused outcome
- **Validation** — exact command(s) / expected output proving completion
- **Maps to** — one or more success criteria (SC) from `docs/spec.md` §5

---

## Success criteria reference (spec §5)

| SC | Criterion | Covered by phase tasks |
|----|-----------|------------------------|
| SC1 | kind cluster reproducible via single command | T1.3 (P1) |
| SC2 | Argo CD + Rollouts + NGINX healthy | T2.4 (P2) |
| SC3 | Argo CD syncs Git → Rollout `Healthy` | T3.3 (P3) |
| SC4 | Canary progresses 20% → 50% → 100% | T4.5 (P4) |
| SC5 | Traffic split verifiable v1 ↔ v2 | T4.6 (P4) |
| SC6 | AnalysisTemplate result influences progression | T4.4 (P4) |
| SC7 | Automatic rollback on analysis failure | T5.2 (P5) |
| SC8 | 100% GitOps flow | T3.3, T4.2, T5.2 (P3/P4/P5) |
| SC9 | Documentation allows reproduction | T6.1 (P6) |
| SC10 | Clean teardown | T1.3/T1.2 (P1), T6.2 (P6) |

---

## Task → Success Criteria coverage matrix

| Task(s) | Success criteria validated |
|---------|---------------------------|
| T0.1 | SC1, SC2, SC9 |
| T1.1–T1.3 | SC1, SC10 |
| T2.1–T2.4 | SC2 |
| T3.1–T3.3 | SC3, SC8 |
| T4.1–T4.6 | SC4, SC5, SC6, SC8 |
| T5.1–T5.2 | SC7, SC8 |
| T6.1–T6.4 | SC9, SC10, DoD |

---

## Risks → owning tasks (spec §7)

| Risk | Mitigation | Owning task(s) |
|------|-----------|----------------|
| NGINX Ingress lacks ALB weight features | Use `nginx.ingress.kubernetes.io/canary*` annotations | T4.3, T4.6 (P4) |
| Metrics unavailable without Prometheus | AnalysisTemplate HTTP verification job fallback | T3.1, T5.1 (P3, P5) |
| Local vs EKS divergence | Document differences + migration map | T6.3 (P6) |
| Insufficient local resources | kind cluster with 1 CP + 2 workers, documented limits | T1.1, T1.3 (P1) |
