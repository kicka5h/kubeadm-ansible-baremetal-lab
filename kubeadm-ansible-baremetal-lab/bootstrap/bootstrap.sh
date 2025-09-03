#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Bootstrap scaffold for kubeadm-ansible-baremetal-lab
# Creates a clean, CI-passing Ansible + Pulumi skeleton and makes the first commit.
# Usage:
#   ./scripts/bootstrap.sh -r <repo_name> -u <github_user> [--force] [--no-git]
# Example:
#   ./scripts/bootstrap.sh -r kubeadm-ansible-baremetal-lab -u kicka5h
# ------------------------------------------------------------------------------

REPO_NAME="kubeadm-ansible-baremetal-lab"
GITHUB_USER="your-username"
FORCE=0
DO_GIT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo) REPO_NAME="$2"; shift 2 ;;
    -u|--user) GITHUB_USER="$2"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    --no-git)  DO_GIT=0; shift ;;
    -h|--help)
      sed -n '1,40p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

confirm_write() {
  local path="$1"
  if [[ -f "$path" && $FORCE -eq 0 ]]; then
    echo "⚠️  Skipping existing file: $path"
    return 1
  fi
  mkdir -p "$(dirname "$path")"
  return 0
}

write_file() {
  local path="$1"
  shift
  if confirm_write "$path"; then
    printf "%s" "$*" > "$path"
    echo "📝 Wrote $path"
  fi
}

write_heredoc() {
  local path="$1"
  shift
  if confirm_write "$path"; then
    cat > "$path" <<'EOF'
'"$@"'
EOF
    # The above trick writes the literal heredoc body; content is passed in caller.
    # (We don't use it here; kept for compatibility.)
    :
  fi
}

# Create folder skeleton
echo "📁 Creating folders …"
mkdir -p "$REPO_NAME"/{ansible/{roles,group_vars,inventories},pulumi,.github/workflows,docs,scripts}
cd "$REPO_NAME"

# README
if confirm_write "README.md"; then
cat > README.md <<'EOF'
# kubeadm-ansible-baremetal-lab

A self-managed Kubernetes lab that provisions raw VMs (via Pulumi, Python), configures a kubeadm cluster (via Ansible), adds CNI/ingress/observability, and runs smoke tests in GitHub Actions.

**Status (initial scaffold):**
- ✅ Ansible project skeleton
- ✅ GitHub Actions CI running `ansible-lint`
- ⏳ Next: add kubeadm roles, Pulumi VM program, E2E workflow
EOF
echo "📝 Wrote README.md"
fi

# .gitignore
if confirm_write ".gitignore"; then
cat > .gitignore <<'EOF'
# Python
__pycache__/
*.pyc
.venv/
venv/

# Ansible
*.retry
ansible/.cache/
ansible/inventories/dynamic.json
*.vault

# Pulumi
Pulumi.*.yaml
pulumi/.pulumi/
pulumi/.venv/
pulumi/venv/
pulumi/__pycache__/

# Replit
.replit
**/.pythonlibs

# Misc
.DS_Store
.idea/
.vscode/
EOF
echo "📝 Wrote .gitignore"
fi

# Makefile (note: recipe line MUST start with a TAB)
if confirm_write "Makefile"; then
cat > Makefile <<'EOF'
.PHONY: lint
lint:
  ansible-lint ansible || true
EOF
echo "📝 Wrote Makefile"
fi

# Ansible core files
if confirm_write "ansible/ansible.cfg"; then
cat > ansible/ansible.cfg <<'EOF'
[defaults]
inventory = inventories
stdout_callback = yaml
timeout = 60
retry_files_enabled = False
interpreter_python = auto_silent
EOF
echo "📝 Wrote ansible/ansible.cfg"
fi

if confirm_write "ansible/requirements.yml"; then
cat > ansible/requirements.yml <<'EOF'
collections:
  - name: kubernetes.core
  - name: community.general
  - name: ansible.posix
EOF
echo "📝 Wrote ansible/requirements.yml"
fi

if confirm_write "ansible/group_vars/all.yml"; then
cat > ansible/group_vars/all.yml <<'EOF'
kubernetes_version: "1.29.0"
cni: "cilium"
EOF
echo "📝 Wrote ansible/group_vars/all.yml"
fi

if confirm_write "ansible/inventories/README.md"; then
cat > ansible/inventories/README.md <<'EOF'
Dynamic inventory will be written here by CI/E2E (e.g., `pulumi stack output > ansible/inventories/dynamic.json`).
EOF
echo "📝 Wrote ansible/inventories/README.md"
fi

if confirm_write "ansible/site.yml"; then
cat > ansible/site.yml <<'EOF'
- name: (Scaffold) Placeholder play to validate CI
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Show scaffold message
      ansible.builtin.debug:
        msg: "Ansible skeleton ready. Add kubeadm roles next."
EOF
echo "📝 Wrote ansible/site.yml"
fi

# Pulumi (stub)
if confirm_write "pulumi/requirements.txt"; then
cat > pulumi/requirements.txt <<'EOF'
pulumi>=3.120.0
# add a provider later, e.g.:
# pulumi-digitalocean
EOF
echo "📝 Wrote pulumi/requirements.txt"
fi

if confirm_write "pulumi/__main__.py"; then
cat > pulumi/__main__.py <<'EOF'
import pulumi
pulumi.export("note", "Scaffold only. Add VM provisioning program here.")
EOF
echo "📝 Wrote pulumi/__main__.py"
fi

# CI workflow
if confirm_write ".github/workflows/ci.yml"; then
cat > .github/workflows/ci.yml <<'EOF'
name: CI (ansible-lint)
on:
  push:
    branches: [ main ]
  pull_request:
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install Ansible + lint
        run: |
          python -m pip install --upgrade pip
          pip install ansible ansible-lint
          ansible --version
      - name: Lint
        run: ansible-lint ansible
EOF
echo "📝 Wrote .github/workflows/ci.yml"
fi

# Docs
if confirm_write "docs/architecture.md"; then
cat > docs/architecture.md <<'EOF'
# Architecture (to be expanded)
- Pulumi provisions raw VMs and outputs an Ansible dynamic inventory.
- Ansible configures OS baseline, containerd, kubeadm (HA optional), CNI, ingress, observability.
- E2E workflow: provision -> configure -> smoke test -> destroy.
EOF
echo "📝 Wrote docs/architecture.md"
fi

# Make the bootstrap (this file) executable if needed (already executing now)
chmod +x scripts/bootstrap.sh || true

# Git init & first commit
if [[ $DO_GIT -eq 1 ]]; then
  if [[ ! -d .git ]]; then
    echo "🔧 Initializing git repo …"
    git init
  fi

  # Ensure main branch
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || git branch -M main || true

  echo "📦 Staging files …"
  git add .

  if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit."
  else
    git commit -m "chore: initial scaffold (ansible + pulumi + CI lint)"
    echo "✅ First commit created."
  fi

  echo
  echo "👉 Next steps:"
  echo "   1) Create the empty GitHub repo: https://github.com/new  (name: $REPO_NAME)"
  echo "   2) In Replit, use the Git panel to connect and Push (recommended on iPad)"
  echo "      OR run:"
  echo "         git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git"
  echo "         git push -u origin main"
fi

echo "🎉 Done."