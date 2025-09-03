#!/usr/bin/env python3
"""
Generate Ansible inventory from Pulumi stack outputs
"""

import json
import subprocess
import sys

def get_pulumi_outputs():
    """Get outputs from Pulumi stack"""
    try:
        result = subprocess.run(
            ["pulumi", "stack", "output", "--json"],
            cwd="../pulumi",
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error getting Pulumi outputs: {e}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing Pulumi outputs: {e}", file=sys.stderr)
        return None

def main():
    """Main function"""
    outputs = get_pulumi_outputs()
    if not outputs:
        print("Failed to get Pulumi outputs", file=sys.stderr)
        sys.exit(1)
    
    if "ansible_inventory" in outputs:
        # Use the pre-generated inventory from Pulumi
        inventory = json.loads(outputs["ansible_inventory"])
    else:
        # Fallback: generate basic inventory from IPs
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
                        "ansible_host": outputs.get("master_ip", "")
                    }
                }
            },
            "workers": {
                "hosts": {}
            }
        }
        
        worker_ips = outputs.get("worker_ips", [])
        for i, worker_ip in enumerate(worker_ips):
            inventory["workers"]["hosts"][f"k8s-worker-{i+1}"] = {
                "ansible_host": worker_ip
            }
    
    # Write inventory to file
    with open("dynamic.json", "w") as f:
        json.dump(inventory, f, indent=2)
    
    print("Inventory generated successfully!")

if __name__ == "__main__":
    main()