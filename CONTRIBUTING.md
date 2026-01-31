# Contributing Guide

## Pre-Commit Hooks Setup

This project uses [pre-commit](https://pre-commit.com/) to run automated code quality checks before each commit.

### Required Tools

Install the following tools before setting up pre-commit hooks:

| Tool | Purpose | Installation |
|------|---------|--------------|
| pre-commit | Hook framework | `pip install pre-commit` or `brew install pre-commit` |
| terraform/tofu | Code formatting | [Install Terraform](https://developer.hashicorp.com/terraform/install) or [Install OpenTofu](https://opentofu.org/docs/intro/install/) |
| tflint | Linting | `brew install tflint` or [download binary](https://github.com/terraform-linters/tflint/releases) |
| tfsec | Security scanning | `brew install tfsec` or [download binary](https://github.com/aquasecurity/tfsec/releases) |

### Installation

1. Install the pre-commit framework:

   ```bash
   pip install pre-commit
   ```

2. Register the git hooks:

   ```bash
   pre-commit install
   ```

3. (Optional) Run hooks on all files to verify setup:

   ```bash
   pre-commit run --all-files
   ```

### What the Hooks Check

- **Trailing whitespace** - Removes trailing whitespace from files
- **End of file fixer** - Ensures files end with a newline
- **YAML validation** - Validates YAML syntax
- **Merge conflict markers** - Detects leftover merge conflict markers
- **Large files** - Prevents files larger than 1000KB from being committed
- **Terraform formatting** - Auto-formats `.tf` and `.tfvars` files
- **TFLint** - Checks for OpenTofu/Terraform best practices and errors
- **TFSec** - Scans for security misconfigurations

### Bypassing Hooks

If you need to bypass hooks temporarily (not recommended):

```bash
git commit --no-verify
```
