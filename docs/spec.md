# POC: GitOps with Argo CD + Argo Rollouts on a local kind cluster

## 1. Purpose

Validate, in a **fully local and cloud-independent** way, the complete GitOps flow for progressive application deployment:

- **Argo CD** as the GitOps engine (declarative sync from Git)
- **Argo Rollouts** as the progressive deployment controller (Canary and/or Blue/Green)
- **kind** as the local Kubernetes cluster
- **NGINX Ingress Controller** as the traffic routing layer (replacing AWS ALB)

The goal is to master the core concepts of Argo Rollouts (`Rollout` CRD, `AnalysisTemplate`, Canary steps, automatic rollback) in a reproducible, low-cost, and quickly recreatable environment, serving as a foundation for later migration to a real EKS cluster.

## 2. Scope

**In scope:**

- Local kind cluster with multiple nodes (control-plane + workers)
- Installation of Argo CD, Argo Rollouts, and NGINX Ingress Controller via Helm
- Demo application (e.g., `rollouts-demo` or a custom app) with two image versions
- **Canary** strategy with traffic splitting via Ingress
- `AnalysisTemplate` with success metrics (e.g., error rate via Prometheus or a verification job)
- GitOps flow: image tag change in Git → automatic Argo CD sync → Rollout progression/rollback
- Reproduction documentation (README/Makefile)

**Out of scope:**

- Real integration with ALB, VPC Lattice, App Mesh, or AWS IAM/IRSA
- Cloud emulators (fakecloud, LocalStack) — recorded decision: not used due to low fidelity
- High availability, multi-cluster, production security
- Large-scale load testing

## 3. POC Architecture
┌─────────────────────────────────────────────────────────────┐
│ kind cluster (local) │
│ │
│ ┌──────────────┐ ┌──────────────┐ ┌────────────────┐ │
│ │ Argo CD │ │ Argo Rollouts│ │ NGINX Ingress │ │
│ │ (GitOps) │──▶│ (controller) │──▶│ Controller │ │
│ └──────┬───────┘ └──────┬───────┘ └───────┬────────┘ │
│ │ │ │ │
│ │ sync │ creates/adjusts │ routes │
│ ▼ ▼ ▼ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Rollout (app) ──▶ stableService / canaryService │ │
│ │ │ │ │
│ │ ├── ReplicaSet stable (v1) │ │
│ │ └── ReplicaSet canary (v2) │ │
│ └──────────────────────────────────────────────────────┘ │
│ │
│ ┌──────────────────┐ │
│ │ Prometheus (opt.)│──▶ AnalysisTemplate (metrics) │
│ └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
▲
│ git push (new image tag)
┌─────┴─────┐
│ Git Repo │
└───────────┘


## 4. Deployment scenario (GitOps flow)

1. **Bootstrap**: kind cluster created; Argo CD, Argo Rollouts, and NGINX Ingress installed via Helm/Makefile.
2. **Initial state**: Git repository contains the `Rollout` (Canary strategy, 20% → 50% → 100%), stable/canary `Service`, `Ingress` with NGINX annotations, `AnalysisTemplate`, and the Argo CD `Application`. App v1 running (100% of traffic).
3. **Change**: commit changing the image tag from `v1` to `v2` in Git.
4. **Sync**: Argo CD detects the drift and syncs the cluster.
5. **Canary progression**: Argo Rollouts creates the canary ReplicaSet (v2) and adjusts the Ingress weights according to the defined steps:
   - `setWeight: 20` → pause (manual or automatic)
   - `AnalysisTemplate` runs → checks success metrics
   - `setWeight: 50` → pause → analysis
   - `setWeight: 100` → promotion completed
6. **Automatic rollback**: if the analysis fails at any step, the Rollout reverts to v1 (100% of traffic) without manual intervention.
7. **Observability**: `kubectl argo rollouts get rollout <app> --watch` and the Argo CD dashboard are used to follow the process.

## 5. Success criteria

The POC will be considered successful if **all** the items below are met:

| # | Criterion | How to validate |
|---|-----------|-----------------|
| 1 | kind cluster comes up reproducibly from a single command (`make up` or script) | Clean execution on a new machine with no hidden manual steps |
| 2 | Argo CD, Argo Rollouts, and NGINX Ingress installed and healthy | `kubectl get pods -A` shows all pods `Running`/`Ready` |
| 3 | Argo CD syncs the Git repository and the `Rollout` reaches `Healthy` state | `argocd app get <app>` shows `Synced` + `Healthy` |
| 4 | Canary deployment progresses through the defined steps (20% → 50% → 100%) | `kubectl argo rollouts get rollout <app> --watch` shows the steps |
| 5 | Traffic split verifiable between v1 and v2 during Canary | Requests to the Ingress return a mix of v1/v2 responses according to the weight |
| 6 | `AnalysisTemplate` runs and its result influences progression | AnalysisRun logs show `Successful` in a healthy scenario |
| 7 | Automatic rollback works when analysis fails | Inject failure (e.g., v2 returning 500 errors) → Rollout aborts and returns to v1 at 100% |
| 8 | 100% GitOps flow: no manual cluster changes to promote/rollback | Every change made via Git commit + Argo CD sync |
| 9 | Documentation allows another person to reproduce the POC | Following the README on a clean machine results in criteria 1–8 |
| 10 | Clean teardown | `make down` removes the cluster and resources without leftovers |

## 6. Repository structure (proposed)
poc-argo-gitops-kind/
├── spec.md
├── README.md
├── Makefile # up / down / sync / status
├── kind/
│ └── cluster.yaml
├── bootstrap/
│ ├── argocd/
│ ├── argo-rollouts/
│ └── ingress-nginx/
├── apps/
│ └── demo/
│ ├── rollout.yaml
│ ├── services.yaml
│ ├── ingress.yaml
│ ├── analysis-template.yaml
│ └── kustomization.yaml
└── argocd/
└── application.yaml


## 7. Risks and mitigation

| Risk | Mitigation |
|------|------------|
| NGINX Ingress does not support all ALB weight features | Use `nginx.ingress.kubernetes.io/canary*` annotations (supported by Argo Rollouts) and validate in criterion 5 |
| Metrics unavailable without Prometheus | Use an `AnalysisTemplate` with a simple HTTP verification job as a fallback |
| Divergence between local behavior and EKS | Explicitly document the differences (Ingress vs ALB, no IRSA) and map what changes during migration |
| Insufficient resources on the local machine | kind cluster with 1 control-plane + 2 workers and documented resource limits |

## 8. Definition of Done (DoD)

- All success criteria (section 5) validated and recorded in the README with evidence (command outputs).
- `make up` and `make down` work on a clean machine.
- Future migration document to EKS (what to replace: Ingress → ALB Ingress, removal of NGINX, IRSA) attached to the repository.

## 9. Tooling versions (baseline)

| Tool | Version | Notes |
|------|---------|-------|
| kind | v0.23.0+ | Cluster provisioning |
| kubectl | v1.29+ | Must match or exceed cluster version |
| Helm | v3.14+ | For all installations |
| Argo CD | v2.11+ | GitOps engine |
| Argo Rollouts | v1.7+ | Progressive delivery controller |
| NGINX Ingress Controller | v1.10+ | Traffic splitting via canary annotations |
| Prometheus (optional) | v2.51+ | Only if metrics-based analysis is enabled |
| kubectl-argo-rollouts plugin | v1.7+ | CLI for observing rollouts |

## 10. Milestones

| # | Milestone | Deliverable |
|---|-----------|-------------|
| M1 | Cluster bootstrap | `make up` creates kind cluster with 1 control-plane + 2 workers |
| M2 | Platform install | Argo CD, Argo Rollouts, NGINX Ingress healthy via Helm |
| M3 | Initial app deploy | Rollout v1 synced by Argo CD, `Healthy`, 100% traffic |
| M4 | Canary happy path | v2 deployed, progresses 20% → 50% → 100%, analysis passes |
| M5 | Rollback path | v2 with injected failure triggers automatic rollback to v1 |
| M6 | Documentation | README reproducible on clean machine; DoD met |

## 11. Acceptance evidence (to be captured in README)

- Output of `kubectl get pods -A` after bootstrap (M2)
- Output of `argocd app get demo` showing `Synced` + `Healthy` (M3)
- Output of `kubectl argo rollouts get rollout demo --watch` during canary (M4)
- Output of `kubectl argo rollouts get rollout demo` after rollback (M5)
- Screenshot or terminal capture of mixed v1/v2 responses during canary (criterion 5)
- `make down` output confirming clean teardown (criterion 10)

## 12. Migration notes to EKS (future reference)

| Local (kind) | EKS equivalent | Change required |
|--------------|----------------|-----------------|
| NGINX Ingress Controller | AWS Load Balancer Controller (ALB Ingress) | Replace Ingress class and annotations |
| `nginx.ingress.kubernetes.io/canary*` annotations | `alb.ingress.kubernetes.io/*` + Argo Rollouts ALB integration | Update Rollout `trafficRouting` block |
| Local image registry | Amazon ECR | Update image references and pull secrets |
| No IAM | IRSA (IAM Roles for Service Accounts) | Attach IAM role to service accounts |
| Prometheus in-cluster | Amazon Managed Prometheus (optional) | Update AnalysisTemplate provider |
| `make up` (kind) | `eksctl` / Terraform | Replace cluster provisioning layer |
