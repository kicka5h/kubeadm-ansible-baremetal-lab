# Architecture (to be expanded)
- Pulumi provisions raw VMs and outputs an Ansible dynamic inventory.
- Ansible configures OS baseline, containerd, kubeadm (HA optional), CNI, ingress, observability.
- E2E workflow: provision -> configure -> smoke test -> destroy.
