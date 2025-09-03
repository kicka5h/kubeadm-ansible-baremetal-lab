import pulumi
import pulumi_digitalocean as digitalocean
import json

# Configuration
config = pulumi.Config()
node_count = config.get_int("node_count") or 3
region = config.get("region") or "nyc3"
instance_size = config.get("instance_size") or "s-2vcpu-2gb"

# SSH Key for accessing droplets
ssh_key = digitalocean.SshKey("kubernetes-lab-key",
    name="kubernetes-lab-key",
    public_key=config.require("ssh_public_key")
)

# Create droplets for Kubernetes cluster
master_node = digitalocean.Droplet("k8s-master",
    name="k8s-master",
    size=instance_size,
    image="ubuntu-22-04-x64",
    region=region,
    ssh_keys=[ssh_key.id],
    tags=["kubernetes", "master"]
)

worker_nodes = []
for i in range(node_count - 1):
    worker = digitalocean.Droplet(f"k8s-worker-{i+1}",
        name=f"k8s-worker-{i+1}",
        size=instance_size,
        image="ubuntu-22-04-x64", 
        region=region,
        ssh_keys=[ssh_key.id],
        tags=["kubernetes", "worker"]
    )
    worker_nodes.append(worker)

# Create Ansible dynamic inventory
def create_inventory(master_ip, worker_ips):
    inventory = {
        "all": {
            "vars": {
                "ansible_user": "root",
                "ansible_ssh_private_key_file": "~/.ssh/id_rsa"
            }
        },
        "masters": {
            "hosts": {
                "k8s-master": {
                    "ansible_host": master_ip
                }
            }
        },
        "workers": {
            "hosts": {}
        }
    }
    
    for i, worker_ip in enumerate(worker_ips):
        inventory["workers"]["hosts"][f"k8s-worker-{i+1}"] = {
            "ansible_host": worker_ip
        }
    
    return json.dumps(inventory, indent=2)

# Generate dynamic inventory
worker_ips = [worker.ipv4_address for worker in worker_nodes]
inventory_json = pulumi.Output.all(master_node.ipv4_address, *worker_ips).apply(
    lambda args: create_inventory(args[0], args[1:])
)

# Exports
pulumi.export("master_ip", master_node.ipv4_address)
pulumi.export("worker_ips", worker_ips)
pulumi.export("ansible_inventory", inventory_json)
pulumi.export("ssh_key_id", ssh_key.id)
