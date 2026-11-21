# POC: GitOps with Argo CD + Argo Rollouts on kind
# Targets: up / down / sync / status

KIND_CLUSTER_NAME ?= poc-argo-gitops
KIND_CONFIG ?= kind/cluster.yaml

.PHONY: up down status sync logs

up:
	kind create cluster --name $(KIND_CLUSTER_NAME) --config $(KIND_CONFIG)

down:
	kind delete cluster --name $(KIND_CLUSTER_NAME)

status:
	kind get clusters

logs:
	kind export logs --name $(KIND_CLUSTER_NAME) --output-dir /tmp/opencode/kind-logs

sync:
	argocd sync demo
