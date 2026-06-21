#!/bin/bash
set -e

echo "Minikube klastera sa Calico CNI (za NetworkPolicies)..."
if ! minikube status >/dev/null 2>&1; then
    minikube start --network-plugin=cni --cni=calico --nodes 2 --cpus 3 --memory 8192
else
    echo "Vec je podignut klaster"
fi

echo "Calico u pripremi"
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector k8s-app=calico-node \
  --timeout=90s || true

echo "Konfigurisanje Helm repoa..."
helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

echo "Kyverno (Policy Engine)..."
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace

echo "Prometheus i Grafana (Monitoring)"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

echo "Osnovna infrastruktura zavrsena"
echo "Napomena: Podovi za Kyverno i Prometheus se asinhrono podižu u pozadini."
