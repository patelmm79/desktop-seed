# Terraform Installation Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Terraform CLI and Terragrunt installation to the desktop deployment script

**Architecture:** Add idempotent install functions using HashiCorp official apt repository for Terraform and direct binary download for Terragrunt

**Tech Stack:** Bash, apt, curl

---

### Task 1: Add terraform component to config.sh

**Files:**
- Modify: `config.sh:68-72` (add after bun entry)

- [ ] **Step 1: Add Terraform component declaration**

Add the following after the bun component (before line 73):

```bash
# Terraform (IaC tool)
COMPONENTS[terraform_name]="Terraform"
COMPONENTS[terraform_check]="command -v terraform &> /dev/null"
COMPONENTS[terraform_required]="false"

# Terragrunt (Terraform wrapper)
COMPONENTS[terragrunt_name]="Terragrunt"
COMPONENTS[terragrunt_check]="command -v terragrunt &> /dev/null"
COMPONENTS[terragrunt_required]="false"
```

- [ ] **Step 2: Commit**

```bash
git add config.sh
git commit -m "feat: add Terraform and Terragrunt to component config"
```

---

### Task 2: Add install_terraform function to deploy-desktop.sh

**Files:**
- Modify: `deploy-desktop.sh:900-930` (add after install_openclaw)
- Modify: `deploy-desktop.sh:1370` (call in main function)
- Modify: `deploy-desktop.sh:1341` (add to dry-run list)

- [ ] **Step 1: Add install_terraform function**

Add after install_openclaw function (around line 900):

```bash
install_terraform() {
    log_info "Installing Terraform and Terragrunt..."

    # Install Terraform from HashiCorp repository
    if ! command -v terraform &> /dev/null; then
        log_info "Installing Terraform CLI..."

        # Add HashiCorp GPG key
        if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
            curl -fsSL https://apt.releases.hashicorp.com/gpg 2>/dev/null | \
                gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
        fi

        # Add HashiCorp repository
        if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > \
                /etc/apt/sources.list.d/hashicorp.list
        fi

        # Install Terraform
        if apt-get update -qq 2>/dev/null && apt-get install -y -qq terraform 2>/dev/null; then
            log_info "Terraform installed successfully"
        else
            log_warn "Failed to install Terraform from repo, trying direct download..."
            # Fallback: direct download
            if curl -fsSL https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip -o /tmp/terraform.zip 2>/dev/null && \
               unzip -o /tmp/terraform.zip -d /usr/local/bin/ 2>/dev/null; then
                chmod +x /usr/local/bin/terraform
                rm -f /tmp/terraform.zip
                log_info "Terraform installed via direct download"
            else
                log_error "Failed to install Terraform"
            fi
        fi
    else
        local tf_version
        tf_version=$(terraform version 2>/dev/null | head -1)
        log_info "Terraform already installed: $tf_version"
    fi

    # Install Terragrunt
    if ! command -v terragrunt &> /dev/null; then
        log_info "Installing Terragrunt..."

        local terragrunt_version="v0.69.0"
        if curl -fsSL "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_amd64" -o /usr/local/bin/terragrunt 2>/dev/null; then
            chmod +x /usr/local/bin/terragrunt
            log_info "Terragrunt installed successfully"
        else
            log_warn "Failed to install Terragrunt"
        fi
    else
        local tg_version
        tg_version=$(terragrunt --version 2>/dev/null | head -1)
        log_info "Terragrunt already installed: $tg_version"
    fi
}
```

- [ ] **Step 2: Add terraform to main() function call list**

In main() function, add after `install_openclaw` (line 1370):

```bash
    install_terraform
```

- [ ] **Step 3: Add Terraform to dry-run output**

In main() dry-run section (around line 1341), add:

```bash
        log_info "  - Terraform"
        log_info "  - Terragrunt"
```

- [ ] **Step 4: Commit**

```bash
git add deploy-desktop.sh
git commit -m "feat: add Terraform and Terragrunt installation"
```

---

### Task 3: Validate syntax and test

**Files:**
- Test: Local bash syntax check

- [ ] **Step 1: Validate bash syntax**

```bash
bash -n deploy-desktop.sh
```

Expected: No output (success)

- [ ] **Step 2: Verify function exists**

```bash
grep -n "^install_terraform" deploy-desktop.sh
```

Expected: Line number where function is defined

- [ ] **Step 3: Verify dry-run shows terraform**

```bash
grep -A2 "OpenCLAW" deploy-desktop.sh | head -5
```

Expected: Shows terraform and terragrunt in dry-run list

- [ ] **Step 4: Commit**

```bash
git commit -m "test: validate terraform installation syntax"
```

---

## Plan Summary

| Task | Files | Key Actions |
|------|-------|-------------|
| 1 | config.sh | Add terraform/terragrunt component declarations |
| 2 | deploy-desktop.sh | Add install_terraform function, call in main, add to dry-run |
| 3 | Local validation | Syntax check and verification |

Total: ~3 tasks, each taking 2-5 minutes
