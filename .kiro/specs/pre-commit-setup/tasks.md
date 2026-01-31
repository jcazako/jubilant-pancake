# Implementation Plan: Pre-Commit Setup

## Overview

This plan implements pre-commit hooks for the LLM inference service project. Tasks are ordered to establish the framework first, then add hooks incrementally from simple to complex.

## Tasks

- [x] 1. Create pre-commit configuration file
  - Create `.pre-commit-config.yaml` in repository root
  - Add general file checks (trailing-whitespace, end-of-file-fixer, check-yaml, check-merge-conflict, check-added-large-files)
  - Configure large file threshold to 1000KB
  - _Requirements: 1.1, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 2. Add OpenTofu formatting hook
  - Add terraform_fmt hook from pre-commit-terraform repository
  - Configure to run on .tf and .tfvars files
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3. Configure TFLint for OpenTofu linting
  - [ ] 3.1 Create `.tflint.hcl` configuration file
    - Enable AWS plugin for AWS-specific rules
    - Enable naming convention rules
    - Enable deprecated syntax detection
    - Enable unused declarations detection
    - _Requirements: 3.2, 3.3_

  - [ ] 3.2 Add terraform_tflint hook to pre-commit config
    - Reference the .tflint.hcl configuration
    - _Requirements: 3.1, 3.4_

- [ ] 4. Add security scanning hook
  - Add terraform_tfsec hook from pre-commit-terraform repository
  - Configure to detect security misconfigurations
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 5. Create setup documentation
  - Add README section or CONTRIBUTING.md with setup instructions
  - Document required tool installations (pre-commit, terraform, tflint, tfsec)
  - Include `pre-commit install` command
  - _Requirements: 1.2, 1.3_

- [ ] 6. Checkpoint - Verify hooks work correctly
  - Run `pre-commit install` to register hooks
  - Run `pre-commit run --all-files` to test all hooks
  - Verify hooks catch formatting issues, linting errors, and security problems
  - _Requirements: 1.4_

## Notes

- All tasks involve creating or modifying configuration files (YAML, HCL)
- No application code changes required
- Manual verification at checkpoint ensures hooks work as expected
