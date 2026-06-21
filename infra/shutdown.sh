#!/bin/bash
set -euo pipefail

namespace="zta-demo"
deployments=(database backend frontend)

echo "Gasenje ${namespace}..."

for deployment in "${deployments[@]}"; do
  if kubectl get deployment "$deployment" -n "$namespace" >/dev/null 2>&1; then
    kubectl scale deployment "$deployment" -n "$namespace" --replicas=0
  else
    echo "${deployment}: deployment ne postoji ${namespace}."
  fi
done