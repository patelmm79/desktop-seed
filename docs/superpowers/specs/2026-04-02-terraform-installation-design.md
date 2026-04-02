# Terraform Installation Design

**Date:** 2026-04-02
**Status:** Approved

## 1. Scope

Add Terraform and related tools to the `deploy-desktop.sh` script for installation on the remote VM.

### Goals
- Enable local Terraform development/testing on the deployed desktop
- Prepare for future Infrastructure-as-Code VM provisioning
- Support multiple cloud providers (AWS, Azure, GCP)

## 2. Installation Approach

**Method:** HashiCorp Official Repository
- Use official HashiCorp apt repository for latest stable Terraform
- Idempotent: safe to run multiple times
- Easy version upgrades via `apt update && apt upgrade`

## 3. Components

| Component | Purpose |
|-----------|---------|
| Terraform CLI | Core infrastructure-as-code tool |
| AWS provider | Manage AWS resources (downloaded on terraform init) |
| Azure provider | Manage Azure resources (downloaded on terraform init) |
| GCP provider | Manage GCP resources (downloaded on terraform init) |
| Terragrunt | Orchestration wrapper for Terraform |

### Note on Providers
Terraform providers are downloaded automatically when running `terraform init` — not installed via apt. The CLI tools (awscli, az, gcloud) are needed for authentication but can be added later if needed.

## 4. Implementation

### deploy-desktop.sh Changes
- Add `install_terraform()` function
- Add to main orchestration (call from main function)
- Follow existing idempotency pattern

### tests/validate-install.sh Changes
- Add Terraform validation check
- Verify `terraform version` works

## 5. Error Handling

- Pre-check: `command -v terraform`
- Post-check: `terraform version`
- Proper logging for debugging

## 6. Acceptance Criteria

- [ ] Terraform CLI installed via HashiCorp repo
- [ ] Terragrunt installed via direct binary
- [ ] Installation is idempotent (safe to re-run)
- [ ] Validation test confirms installation
- [ ] Works on Ubuntu 20.04+, 22.04, 24.04
