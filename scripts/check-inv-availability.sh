#!/usr/bin/env bash
# Read-only check: is Isovalent Networking for Virtualization (INV) /
# Isovalent Private Networks daadwerkelijk beschikbaar op dit cluster?
# Vereist: kubectl met geldige context. Geen mutaties.
set -euo pipefail

echo "=== Isovalent/Cilium CRD's ==="
kubectl get crd 2>&1 | grep -E 'cilium\.io|isovalent\.com' || echo "Geen Cilium/Isovalent CRD's gevonden - is Cilium uberhaupt geinstalleerd?"

echo
echo "=== Specifiek: INV/IPN CRD's ==="
echo "(let op: de CRD-naam voor 'Private Networks' varieert per Cilium"
echo " Enterprise-versie - op v1.18.11-cee.1 heet dit isovalentpodnetworks,"
echo " nieuwere/andere docs noemen clusterwideprivatenetworks. Check beide.)"
for crd in clusterwideprivatenetworks.isovalent.com isovalentpodnetworks.isovalent.com isovalentnetworkpolicies.isovalent.com; do
  if kubectl get crd "$crd" >/dev/null 2>&1; then
    echo "OK    $crd"
  else
    echo "MIST  $crd"
  fi
done
echo
echo "Als isovalentpodnetworks OK is maar clusterwideprivatenetworks MIST:"
echo "  kubectl explain isovalentpodnetwork --recursive"
echo "  kubectl explain isovalentpodnetwork.spec"
echo "om te zien of dit dezelfde feature is (en of er al een VLAN-veld in zit)."

echo
echo "=== Cilium agent image (check op Isovalent Enterprise build) ==="
kubectl -n kube-system get ds cilium -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' 2>&1 || echo "cilium DaemonSet niet gevonden in kube-system"

echo
echo "=== cilium-cli status (indien geinstalleerd op dit systeem) ==="
command -v cilium >/dev/null 2>&1 && cilium status --verbose || echo "cilium CLI niet geinstalleerd op dit systeem - installeer evt. even voor een uitgebreidere check"
