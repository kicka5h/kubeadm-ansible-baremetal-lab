# kubeadm-ansible-baremetal-lab

A self-managed Kubernetes lab that provisions raw VMs on Digital Ocean (via Pulumi + Python), configures a kubeadm cluster (via Ansible), adds CNI/ingress/observability, and runs automated deployment through GitHub Actions.

## Overview

This project creates a production-ready Kubernetes cluster from scratch using kubeadm on bare-metal-style VMs. Unlike managed Kubernetes services, this gives you full control over the cluster configuration, networking, and components.

## Architecture

- **Pulumi** provisions Ubuntu 22.04 droplets on Digital Ocean
- **Dynamic inventory generation** bridges Pulumi outputs to Ansible configuration  
- **Ansible** manages the complete cluster configuration lifecycle using kubeadm
- **GitHub Actions** provides CI/CD for automated cluster deployment and teardown

### Cluster Components

- **Master node**: Single control plane with kubeadm initialization
- **Worker nodes**: Configurable number of worker nodes (default: 2)
- **Container runtime**: containerd
- **CNI**: Cilium for networking
- **OS**: Ubuntu 22.04 LTS

## Prerequisites

### Local Development
- Python 3.11+
- Pulumi CLI
- Ansible
- Digital Ocean account and API token

### GitHub Actions (Production)
Configure these secrets in your GitHub repository:
- `PULUMI_ACCESS_TOKEN` - Pulumi Cloud access token
- `SSH_KEY` - Private SSH key for VM access
- `DIGITALOCEAN_TOKEN` - Digital Ocean API token

## Quick Start

### Local Deployment

1. **Install dependencies**
   ```bash
   cd pulumi
   pip install -r requirements.txt
   pip install ansible ansible-lint
   ```

2. **Configure Pulumi**
   ```bash
   cd pulumi
   pulumi login
   pulumi stack init dev
   pulumi config set digitalocean:token <your-do-token>
   pulumi config set ssh_public_key "$(cat ~/.ssh/id_rsa.pub)"
   ```

3. **Deploy infrastructure**
   ```bash
   pulumi up
   ```

4. **Generate inventory and configure cluster**
   ```bash
   cd ../ansible/inventories
   python3 generate_inventory.py
   cd ..
   ansible-playbook -i inventories/dynamic.json site.yml
   ```

5. **Access your cluster**
   ```bash
   # SSH to master node
   ssh root@$(cd ../pulumi && pulumi stack output master_ip)
   
   # Check cluster status
   kubectl get nodes
   ```

### GitHub Actions Deployment

1. **Set up repository secrets** (Settings → Secrets and variables → Actions):
   - `PULUMI_ACCESS_TOKEN`
   - `SSH_KEY` 
   - `DIGITALOCEAN_TOKEN`

2. **Deploy cluster**
   - Push to main branch, or
   - Manually trigger the "Deploy Kubernetes Cluster" workflow

3. **Clean up resources**
   - Manually trigger the "Cleanup Kubernetes Cluster" workflow

## Project Structure

```
├── .github/workflows/          # GitHub Actions workflows
│   ├── deploy-cluster.yml      # Automated deployment
│   └── cleanup-cluster.yml     # Resource cleanup
├── ansible/                    # Kubernetes cluster configuration
│   ├── roles/                  # Ansible roles
│   │   ├── common/             # Base system setup
│   │   ├── kubeadm-master/     # Control plane initialization
│   │   └── kubeadm-worker/     # Worker node joining
│   ├── inventories/            # Dynamic inventory management
│   ├── group_vars/all.yml      # Cluster configuration
│   └── site.yml                # Main playbook
├── pulumi/                     # Infrastructure provisioning
│   ├── __main__.py             # Digital Ocean VM definitions
│   ├── Pulumi.yaml             # Project configuration
│   └── requirements.txt        # Python dependencies
└── docs/                       # Architecture documentation
```

## Configuration

### Cluster Sizing
```bash
# Configure cluster size (default: 3 total nodes)
pulumi config set node_count 5

# Configure instance size (default: s-2vcpu-2gb)
pulumi config set instance_size s-4vcpu-4gb

# Configure region (default: nyc3)
pulumi config set region fra1
```

### Kubernetes Version
Edit `ansible/group_vars/all.yml`:
```yaml
kubernetes_version: "1.29.0"  # Change to desired version
cni: "cilium"                 # CNI provider
```

## Available Commands

```bash
# Run Ansible linting
make lint

# Manual Ansible execution
ansible-playbook -i inventories/dynamic.json site.yml

# Preview infrastructure changes
cd pulumi && pulumi preview

# Deploy infrastructure
cd pulumi && pulumi up

# Destroy infrastructure
cd pulumi && pulumi destroy
```

## Troubleshooting

### SSH Connection Issues
- Ensure your SSH key is correctly configured in Pulumi config
- Verify Digital Ocean droplets have your SSH key assigned
- Check security group rules allow SSH (port 22)

### Ansible Failures
- Verify dynamic inventory was generated: `cat ansible/inventories/dynamic.json`
- Test connectivity: `ansible -i inventories/dynamic.json all -m ping`
- Check VM readiness: VMs need ~60 seconds to fully boot

### Cluster Issues
- SSH to master node and check: `kubectl get nodes`
- Verify containerd is running: `systemctl status containerd`
- Check kubeadm logs: `journalctl -u kubelet`

## Security Considerations

- All VMs use SSH key authentication (no passwords)
- Cluster API server is accessible from internet (change for production)
- Consider implementing network policies and RBAC
- Regular security updates recommended

## Cost Management

**Important**: This creates billable resources on Digital Ocean. Use the cleanup workflow or `pulumi destroy` to avoid ongoing charges.

Default configuration costs approximately:
- 3 × s-2vcpu-2gb droplets: ~$36/month
- Network transfer and storage: ~$5/month

## Contributing

1. Run `make lint` before submitting changes
2. Test changes with a full deployment cycle
3. Update documentation for configuration changes
4. Follow existing Ansible and Pulumi conventions

## License

This project is open source and available under the MIT License.