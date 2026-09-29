#!/usr/bin/env bash
# Baseline-snapshot van gslb-app en Hubble/Cilium, VOOR er iets aan deze repo
# wordt toegepast. Draai dit, bewaar de output, en draai het na afloop
# nogmaals om te bevestigen dat er niets veranderd is aan bestaande workloads.
#
# Vereist: kubectl met geldige context naar het doelcluster (DC1 of DC2).
# Puur read-only - geen enkele mutatie.
set -euo pipefail

GSLB_NS="gslb-app"

echo "=== Timestamp ==="
date -u

echo
echo "=== gslb-app (namespace: $GSLB_NS) ==="
kubectl get all -n "$GSLB_NS" 2>&1 || echo "LET OP: namespace '$GSLB_NS' niet gevonden - pas GSLB_NS env var aan naar de juiste naam"

echo
echo "=== Alle namespaces/resources met 'gslb' in de naam (fallback-zoekactie) ==="
kubectl get deploy,statefulset,pod -A 2>&1 | grep -i gslb || echo "niets gevonden op naam 'gslb'"

echo
echo "=== Cilium DaemonSet ==="
kubectl -n kube-system get ds cilium -o wide 2>&1 || echo "cilium DaemonSet niet gevonden in kube-system"

echo
echo "=== Hubble relay/UI ==="
kubectl -n kube-system get deploy,pod -l k8s-app=hubble-relay 2>&1
kubectl -n kube-system get deploy,pod -l k8s-app=hubble-ui 2>&1

echo
echo "=== Bestaande CiliumNetworkPolicy / CiliumClusterwideNetworkPolicy (alle namespaces) ==="
kubectl get ciliumnetworkpolicies.cilium.io -A 2>&1
kubectl get ciliumclusterwidenetworkpolicies.cilium.io 2>&1

echo
echo "=== Cilium/Hubble health ==="
command -v cilium >/dev/null 2>&1 && cilium status || echo "cilium CLI niet geinstalleerd - sla health-check over"
