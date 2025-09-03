# Overview

This is a self-managed Kubernetes lab infrastructure project that automates the provisioning and configuration of a bare-metal Kubernetes cluster. The project combines Pulumi for infrastructure provisioning, Ansible for cluster configuration, and GitHub Actions for CI/CD automation. It's designed to create repeatable Kubernetes environments for testing and learning purposes.

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Infrastructure as Code
- **Pulumi** handles VM provisioning using Python to create DigitalOcean droplets
- **Dynamic inventory generation** bridges Pulumi outputs to Ansible configuration
- Infrastructure is defined declaratively with configurable parameters (node count, region, instance size)

## Configuration Management
- **Ansible** manages the complete cluster configuration lifecycle
- **Role-based structure** for organizing kubeadm installation, CNI setup, and observability components
- **Dynamic inventory** automatically generated from Pulumi stack outputs

## Cluster Architecture
- **Single master node** with configurable worker nodes (default 3 total nodes)
- **Ubuntu 22.04** as the base operating system
- **kubeadm** for Kubernetes cluster bootstrapping
- **containerd** as the container runtime

## Automation Pipeline
- **GitHub Actions** provides CI/CD with automated linting and testing
- **End-to-end workflow** supports full lifecycle: provision → configure → test → destroy
- **Ansible-lint** integration for configuration validation

## Network and Access
- **SSH key-based authentication** for secure VM access
- **DigitalOcean networking** with configurable regions
- **Tag-based organization** for resource management (kubernetes, master, worker tags)

# External Dependencies

## Cloud Infrastructure
- **DigitalOcean** - Primary cloud provider for VM hosting
- **DigitalOcean SSH Keys** - Authentication mechanism for droplet access

## Development Tools
- **Pulumi** (v3.120.0+) - Infrastructure provisioning and state management
- **Ansible** - Configuration management and cluster setup
- **GitHub Actions** - CI/CD pipeline and automation

## Runtime Dependencies
- **Python 3** - Required for Pulumi programs and inventory generation
- **pulumi-digitalocean** (v4.0.0+) - DigitalOcean provider for Pulumi

## Planned Integrations
- **CNI provider** - Container networking interface (to be configured)
- **Ingress controller** - External traffic management (to be added)
- **Observability stack** - Monitoring and logging components (planned)