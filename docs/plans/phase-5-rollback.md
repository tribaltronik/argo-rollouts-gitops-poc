# Phase 5 — Rollback

**Milestone:** M5 — Rollback path (`docs/spec.md` §10)
**Goal:** A failing v2 analysis triggers automatic rollback to v1 at 100% traffic.

## Tasks

### T5.1 — Inject failure for v2
- **Objective:** Cause v2 health check / metrics failure (e.g., failing image → 500 errors).
- **Validation:** Rollout or analysis enters failing state.

### T5.2 — Confirm automatic rollback to v1
- **Objective:** Verify Argo Rollouts aborts and reverts to v1 at 100% traffic without manual intervention.
- **Validation:** **SC7** — Rollout reverts to v1, 100% traffic; failure was analysis-driven, not manual (SC8).

## Exit criteria
- SC7 and SC8 satisfied — automatic rollback works.
