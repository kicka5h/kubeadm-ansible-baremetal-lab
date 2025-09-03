# kubeadm-ansible-baremetal-lab

A self-managed Kubernetes lab that provisions raw VMs (via Pulumi, Python), configures a kubeadm cluster (via Ansible), adds CNI/ingress/observability, and runs smoke tests in GitHub Actions.

**Status (initial scaffold):**
- ✅ Ansible project skeleton
- ✅ GitHub Actions CI running `ansible-lint`
- ⏳ Next: add kubeadm roles, Pulumi VM program, E2E workflow

