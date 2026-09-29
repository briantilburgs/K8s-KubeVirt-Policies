# K8s-KubeVirt-Policies

PoC en voorbereidend werk voor het vervangen van VMware NSX-microsegmentatie
door Cilium/Isovalent-policies, voor KubeVirt VM's op de bestaande DC1- en
DC2-Kubernetes-clusters (gekoppeld via Cilium Cluster Mesh).

## Niet-onderhandelbaar

**Deze deployment mag de bestaande `gslb-app`- en Hubble-configuraties niet
breken.** Alles moet blijven werken zoals het nu werkt. Concreet betekent dat:

- KubeVirt is CNI-onafhankelijk en installeert uitsluitend in zijn eigen
  `kubevirt`-namespace - het raakt geen bestaande Cilium-configuratie,
  CiliumNetworkPolicy's, of andere namespaces.
- Draai altijd eerst `scripts/preflight-check.sh` (zie hieronder) vóór je
  iets uit deze repo toepast, bewaar de output, en draai het script nogmaals
  na afloop om te bevestigen dat er niets aan bestaande workloads veranderd is.
- Nieuwe policies worden namespaced en met strakke, unieke label-selectors
  geschreven (nooit clusterwide, nooit brede/gedeelde labels) om overlap met
  bestaande workloads te voorkomen.

## Status / openstaande punten

- VLAN/FortiGate-koppeling (Isovalent Private Networks, Local Access-modus)
  staat nog niet in de manifesten: de exacte host-voorbereiding is nog niet
  bevestigd door Isovalent/Cisco (zie `ansible/playbooks/prepare-vlan-trunk.yml`).
- Licentie is geen blokkade (betaald bij Cisco, geen technisch te
  implementeren certificaat nodig) - INV kan dus gebruikt worden zodra de
  VLAN-koppeling duidelijk is.

## Structuur

```
VM-flow-template.xlsx        Aanvraagformaat: Workloads- en Flows-tabblad
manifests/
  00-namespace.yaml           nsx-app1 namespace (PoC-workloads)
  kubevirt/                   KubeVirt-operator installatie (gepind op v1.9.0)
  vms/                        VirtualMachine-manifesten (Cirros, 1 interface, pod-netwerk)
  services/                   Stabiele DNS-namen per VM, voor testdoeleinden
  network-policies/           CiliumNetworkPolicy per workload + namespace-brede default-deny
scripts/
  preflight-check.sh          Baseline-snapshot van gslb-app/Hubble/Cilium (voor/na vergelijking)
  check-inv-availability.sh   Read-only check of INV/Isovalent Private Networks beschikbaar is
ansible/
  inventory/hosts.yaml.example
  playbooks/
    prepare-kubevirt-nodes.yml  Read-only KVM-check per node (geen auto-fix)
    prepare-vlan-trunk.yml      Placeholder - wacht op Isovalent-bevestiging
```

## Uitrolvolgorde

1. **Preflight**: `GSLB_NS=<echte-namespace> ./scripts/preflight-check.sh > preflight-$(date +%F).log`
   op elk cluster (DC1, DC2) met een kubectl-context die daarnaartoe wijst.
2. **Node-check**: `ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/prepare-kubevirt-nodes.yml`
   - faalt zichtbaar als een node geen `/dev/kvm` heeft; los dat eerst op.
3. **KubeVirt installeren**:
   ```
   kubectl apply -k manifests/kubevirt/
   kubectl -n kubevirt wait kv kubevirt --for condition=Available --timeout=5m
   ```
4. **INV-check** (informatief, voor de latere VLAN-fase):
   `./scripts/check-inv-availability.sh`
5. **PoC-workloads en policies**:
   ```
   kubectl apply -f manifests/00-namespace.yaml
   kubectl apply -R -f manifests/vms/
   kubectl apply -R -f manifests/services/
   kubectl apply -R -f manifests/network-policies/
   ```
   Dezelfde manifesten ongewijzigd op zowel DC1 als DC2 toepassen (alle flows
   in dit template zijn scope `lokaal`).
6. **Bevestigen**: `preflight-check.sh` nogmaals draaien en met de baseline
   uit stap 1 vergelijken.

## Testen

Elke VM start via cloud-init een kale `nc -l -p 8080`-listener. Test de
Flows-tab-verwachtingen met bijvoorbeeld:
```
nc -zv nsx-app1-appl.nsx-app1.svc.cluster.local 8080
```
en bekijk de allow/deny-beslissingen live in Hubble.
