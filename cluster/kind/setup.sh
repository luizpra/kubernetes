#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEFAULT_VERSION="v1.34.0"

if [ -z "${K8S_VERSION:-}" ]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  BRANCH_VERSION="$(echo "${BRANCH}" | grep -oP 'v\d+\.\d+\.\d+' || echo "")"

  if [ -n "${BRANCH_VERSION}" ]; then
    K8S_VERSION="${BRANCH_VERSION}"
  else
    K8S_VERSION="${DEFAULT_VERSION}"
  fi
fi

CLUSTER_NAME="${1:-kind}"

export K8S_VERSION

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  read -rp "Kind cluster '${CLUSTER_NAME}' already exists. Delete and recreate? [y/N]: " answer
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    echo "Deleting existing Kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "${CLUSTER_NAME}"
  else
    echo "Aborting."
    exit 0
  fi
fi

echo "Creating Kind cluster '${CLUSTER_NAME}' with Kubernetes ${K8S_VERSION}..."
envsubst < "${SCRIPT_DIR}/kind-3w-1cp.yml" | kind create cluster --name "${CLUSTER_NAME}" --config=-
