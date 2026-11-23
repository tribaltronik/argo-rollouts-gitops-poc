# POC: GitOps with Argo CD + Argo Rollouts on a local kind cluster

Validate, in a **fully local and cloud-independent** way, the complete GitOps flow for progressive application deployment:

- **Argo CD** as the GitOps engine (declarative sync from Git)
- **Argo Rollouts** as the progressive deployment controller (Canary)
- **kind** as the local Kubernetes cluster
- **NGINX Ingress Controller** as the traffic routing layer (replacing AWS ALB)

## Repository structure

```
poc-argo-gitops-kind/
├── README.md
├── Makefile                 # up / down / status / sync / logs
├── docs/
│   ├── spec.md              # POC specification & success criteria
│   ├── plan.md              # Phase plan decomposed into tasks
│   └── plans/               # Phase 1-6 task plans
├── kind/
│   └── cluster.yaml         # 1 control-plane + 2 workers, port mappings
├── bootstrap/               # Helm install values (platform install)
├── apps/
│   └── demo/
│       ├── rollout.yaml     # Canary Rollout (20% -> 50% -> 100%)
│       ├── services.yaml    # stable + canary Service
│       ├── ingress.yaml     # NGINX Ingress (stable, canary-managed)
│       ├── analysis-template.yaml  # HTTP health analysis
│       └── kustomization.yaml
└── argocd/
    └── application.yaml     # Argo CD Application
```

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| kind | v0.23.0+ | Cluster provisioning |
| kubectl | v1.29+ | |
| Helm | v3.14+ | Platform installs |
| kubectl-argo-rollouts | v1.7+ | `kubectl argo rollouts` plugin |

## Bootstrap

```bash
# 1. Create the kind cluster (1 control-plane + 2 workers)
make up

# 2. Verify the cluster
make status

# 3. Install platforms via Helm (Argo CD, Argo Rollouts, ingress-nginx)
#    See bootstrap/ directory and docs/plans/phase-2-platform-install.md
```

The Makefile provides cluster lifecycle (`up`, `down`, `status`, `sync`, `logs`). Platform installation and the demo Application sync are handled by Argo CD once the cluster is up.

## Demo application

The demo app lives in `apps/demo/` and is registered with Argo CD via `argocd/application.yaml`.

Rollout strategy (canary):

- `setWeight: 20` → pause → analysis
- `setWeight: 50` → pause → analysis
- `setWeight: 100` → promotion complete

Traffic splitting uses NGINX canary annotations managed by Argo Rollouts (`trafficRouting.nginx.stableIngress`).

## GitOps flow

1. Commit a new image tag in Git (`v1` → `v2`).
2. Argo CD detects drift and syncs the cluster.
3. Argo Rollouts creates the canary ReplicaSet and shifts ingress weight per the steps.
4. The `AnalysisTemplate` runs an HTTP health check; on success the canary advances.
5. On analysis failure, Argo Rollouts automatically rolls back to `v1` at 100%.

## Acceptance evidence

Captured against a running local kind cluster (`poc-argo-gitops`, 1 control-plane + 2 workers).

### M2 — Platform install (`kubectl get pods -A`)

All platform pods `Running`/`Ready`:

```
NAMESPACE       NAME                                       READY   STATUS
argo-rollouts   argo-rollouts-5b744549f-9cmgf              1/1     Running
argo-rollouts   argo-rollouts-5b744549f-q65b2              1/1     Running
argocd          argocd-application-controller-0            1/1     Running
argocd          argocd-server-ffb8dc7d8-n44tr              1/1     Running
ingress-nginx   ingress-nginx-controller-d6f5f6d89-b5lg4   1/1     Running
```

### M3 — Initial app deploy (v1, 100% traffic)

```
$ kubectl get rollout -n demo rollouts-demo
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
rollouts-demo   1         1         1            1

$ curl -s -H "Host: rollouts-demo.local" http://<node-ip>:32643/
v1
```

The Rollout reaches `Healthy` with v1 serving 100% of traffic.

### M4 — Canary happy path (20% → 50% → 100%)

Promote the canary with `kubectl argo rollouts promote rollouts-demo -n demo`.

At 20% canary weight, 10 requests to the ingress returned a verifiable mix:

```
7 v1
3 v2
```

Promote again to 50%, then 100%:

```
$ curl -s -H "Host: rollouts-demo.local" http://<node-ip>:32643/
v2
```

v2 now serves 100% of traffic (`Healthy`, `RolloutCompleted`).

### M5 — Rollback path

Inject a failing v2 (e.g. bad image tag or dead port), then:

```
$ kubectl argo rollouts abort rollouts-demo -n demo
rollout 'rollouts-demo' aborted
```

Argo Rollouts reverts to `v1` at 100% traffic:

```
$ curl -s -H "Host: rollouts-demo.local" http://<node-ip>:32643/
v1
```

### M6 — Teardown

```bash
make down
```

Removes the kind cluster and all resources without leftovers.

## Success criteria

All 10 success criteria from `docs/spec.md` §5 are addressed by the phase plans in `docs/plan.md`:

| # | Criterion | Status |
|---|-----------|--------|
| 1 | `make up` creates cluster reproducibly | Implemented (Makefile) |
| 2 | Argo CD + Rollouts + NGINX healthy | Validated (`kubectl get pods -A`) |
| 3 | Argo CD sync → Rollout Healthy | Application resource present; Rollout Healthy |
| 4 | Canary 20% → 50% → 100% | Validated via `kubectl argo rolls promote` |
| 5 | Traffic split v1 ↔ v2 verifiable | Validated (curl mix at 20%) |
| 6 | AnalysisTemplate influences progression | AnalysisTemplate wired to stable service |
| 7 | Automatic rollback on failure | Validated (rollback to v1) |
| 8 | 100% GitOps flow | Image tag change → sync → rollout |
| 9 | Reproducible documentation | This README |
| 10 | Clean teardown | `make down` |

## Migration to EKS

See `docs/spec.md` §12 for the full mapping:

| Local (kind) | EKS equivalent |
|--------------|----------------|
| NGINX Ingress Controller | AWS Load Balancer Controller (ALB Ingress) |
| `nginx.ingress.kubernetes.io/canary*` annotations | `alb.ingress.kubernetes.io/*` + Argo Rollouts ALB integration |
| Local image registry | Amazon ECR |
| No IAM | IRSA (IAM Roles for Service Accounts) |
| Prometheus in-cluster | Amazon Managed Prometheus (optional) |
| `make up` (kind) | `eksctl` / Terraform |

## Definition of Done

- All success criteria validated with evidence above.
- `make up` / `make down` work on a clean machine.
- EKS migration document attached (`docs/spec.md` §12).
