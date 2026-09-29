#!/usr/bin/env bash
# Read-only check: is Isovalent Networking for Virtualization (INV) /
# Isovalent Private Networks daadwerkelijk beschikbaar op dit cluster?
# Vereist: kubectl met geldige context. Geen mutaties.
set -euo pipefail

echo "=== Isovalent/Cilium CRD's ==="
kubectl get crd 2>&1 | grep -E 'cilium\.io|isovalent\.com' || echo "Geen Cilium/Isovalent CRD's gevonden - is Cilium uberhaupt geinstalleerd?"

echo
echo "=== Specifiek: INV/IPN CRD's (namen zoals bevestigd in Isovalent-documentatie) ==="
for crd in clusterwideprivatenetworks.isovalent.com isovalentnetworkpolicies.isovalent.com; do
  if kubectl get crd "$crd" >/dev/null 2>&1; then
    echo "OK    $crd"
  else
    echo "MIST  $crd  <- INV is (nog) niet geinstalleerd/beschikbaar op dit cluster"
  fi
done

echo
echo "=== Cilium agent image (check op Isovalent Enterprise build) ==="
kubectl -n kube-system get ds cilium -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' 2>&1 || echo "cilium DaemonSet niet gevonden in kube-system"

echo
echo "=== cilium-cli status (indien geinstalleerd op dit systeem) ==="
command -v cilium >/dev/null 2>&1 && cilium status --verbose || echo "cilium CLI niet geinstalleerd op dit systeem - installeer evt. even voor een uitgebreidere check"
