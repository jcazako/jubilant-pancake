# Implementation Plan: LLM Inference Service

## Overview

This plan implements a Phi-3 mini LLM inference service on AWS using OpenTofu. The implementation follows a modular approach, building infrastructure components incrementally with validation at each step.

## Tasks

- [ ] 1. Set up project structure and OpenTofu configuration
  - [x] 1.1 Create directory structure for OpenTofu modules
    - Create `infrastructure/` root with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
    - Create module directories: `networking/`, `compute/`, `load_balancer/`, `api_gateway/`, `monitoring/`
    - Create `environments/` with `dev.tfvars` and `prod.tfvars`
    - _Requirements: 2.1, 2.2_
  - [x] 1.2 Configure OpenTofu backend for remote state
    - Create `backend.tf` with S3 backend configuration
    - Configure DynamoDB table for state locking
    - _Requirements: 2.5_
  - [x] 1.3 Define root variables and provider configuration
    - Define all input variables with validation rules
    - Configure AWS provider with region variable
    - _Requirements: 2.4_

- [x] 2. Implement networking module
  - [x] 2.1 Create VPC and subnet configuration
    - Create VPC with DNS support
    - Create public subnets across multiple AZs for ALB
    - Create private subnets across multiple AZs for GPU instances
    - Create Internet Gateway and NAT Gateway
    - Configure route tables
    - _Requirements: 6.1, 6.2, 6.3_
  - [x] 2.2 Create security groups
    - Create ALB security group allowing HTTPS (443) from internet
    - Create EC2 security group allowing traffic only from ALB
    - _Requirements: 6.4, 6.5_
  - [x] 2.3 Write property test for multi-AZ distribution
    - **Property 4: Multi-AZ Distribution**
    - **Validates: Requirements 6.1**
  - [x] 2.4 Write property test for security group least privilege
    - **Property 5: Security Group Least Privilege**
    - **Validates: Requirements 6.4**

- [ ] 3. Checkpoint - Verify networking module
  - Ensure `tofu validate` passes for networking module
  - Ensure all tests pass, ask the user if questions arise

- [ ] 4. Implement compute module
  - [ ] 4.1 Create launch template for GPU instances
    - Configure g5.xlarge instance type with Deep Learning AMI
    - Create user data script to install vLLM and start Phi-3 mini
    - Configure 100GB gp3 root volume
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 4.2 Create Auto Scaling Group with scaling policies
    - Configure ASG with min/max instance variables
    - Create scale-up policy for GPU utilization > 70%
    - Create scale-down policy for GPU utilization < 30%
    - Configure target group attachment
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 4.3 Create IAM role and instance profile
    - Create IAM role with CloudWatch and ECR permissions
    - Attach instance profile to launch template
    - _Requirements: 1.4_
  - [ ] 4.4 Write property test for minimum instance guarantee
    - **Property 3: Minimum Instance Guarantee**
    - **Validates: Requirements 3.3**

- [ ] 5. Implement load balancer module
  - [ ] 5.1 Create Application Load Balancer
    - Create ALB in public subnets
    - Configure HTTP to HTTPS redirect listener
    - Configure HTTPS listener with ACM certificate
    - _Requirements: 6.3_
  - [ ] 5.2 Create target group with health checks
    - Configure target group for port 8000
    - Set health check path to /health with 30s interval
    - Configure healthy/unhealthy thresholds
    - _Requirements: 1.4, 7.4_

- [ ] 6. Checkpoint - Verify compute and load balancer modules
  - Ensure `tofu validate` passes for all modules
  - Ensure all tests pass, ask the user if questions arise

- [ ] 7. Implement API Gateway module
  - [ ] 7.1 Create HTTP API with VPC Link
    - Create API Gateway HTTP API
    - Create VPC Link for private ALB integration
    - Configure routes for /v1/completions (POST) and /health (GET)
    - Set 30 second timeout
    - _Requirements: 5.1, 5.2, 7.2_
  - [ ] 7.2 Create WAF with IP-based rate limiting
    - Create WAF Web ACL with rate-based rule
    - Configure 100 requests per minute per IP limit
    - Associate WAF with API Gateway
    - _Requirements: 5.3, 5.4_
  - [ ] 7.3 Configure optional API key authentication
    - Create API key resource (optional via variable)
    - Configure usage plan if API key enabled
    - _Requirements: 5.5_

- [ ] 8. Implement monitoring module
  - [ ] 8.1 Create CloudWatch log groups
    - Create log group for vLLM logs
    - Configure 30-day retention
    - _Requirements: 4.6_
  - [ ] 8.2 Create CloudWatch alarms
    - Create alarm for p99 latency > 5 seconds
    - Create alarm for high error rate
    - Configure SNS topic for notifications
    - _Requirements: 4.4_
  - [ ] 8.3 Create CloudWatch dashboard
    - Add widgets for latency metrics (p50, p95, p99)
    - Add widgets for throughput and GPU utilization
    - Add widgets for instance count and estimated cost
    - _Requirements: 4.1, 4.2, 4.3, 4.5_
  - [ ] 8.4 Write property test for monitoring completeness
    - **Property 6: Monitoring Completeness**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.5**

- [ ] 9. Implement demo interface module
  - [ ] 9.1 Create S3 bucket and CloudFront distribution
    - Create S3 bucket for static website hosting
    - Create CloudFront distribution with OAC
    - Configure cache behaviors
    - _Requirements: 8.4_
  - [ ] 9.2 Create demo web page
    - Create index.html with prompt input and response display
    - Create style.css with clean, minimal styling
    - Create app.js with API interaction logic
    - _Requirements: 8.1, 8.2, 8.3_
  - [ ] 9.3 Configure CORS on API Gateway
    - Add CORS headers to API Gateway responses
    - Allow requests from CloudFront domain
    - _Requirements: 8.5_

- [ ] 10. Checkpoint - Verify all modules
  - Ensure `tofu validate` passes for complete configuration
  - Ensure all tests pass, ask the user if questions arise

- [ ] 11. Wire modules together in root configuration
  - [ ] 11.1 Create root main.tf with module calls
    - Wire networking outputs to compute inputs
    - Wire load balancer outputs to API gateway inputs
    - Wire ASG outputs to monitoring inputs
    - Wire API endpoint to demo module
    - _Requirements: 2.1, 2.3_
  - [ ] 11.2 Create root outputs
    - Output API endpoint URL
    - Output CloudWatch dashboard URL
    - Output ALB DNS name
    - Output demo URL
    - _Requirements: 2.1_
  - [ ] 11.3 Write property test for resource completeness
    - **Property 1: Resource Completeness**
    - **Validates: Requirements 2.1**
  - [ ] 11.4 Write property test for environment parameterization
    - **Property 2: Environment Parameterization**
    - **Validates: Requirements 2.4**

- [ ] 12. Create environment variable files
  - [ ] 12.1 Create dev.tfvars
    - Configure dev environment with smaller instance limits
    - Set appropriate scaling thresholds
    - _Requirements: 2.4_
  - [ ] 12.2 Create prod.tfvars
    - Configure prod environment with production-ready settings
    - Set appropriate scaling thresholds
    - _Requirements: 2.4_

- [ ] 13. Implement GitHub Actions CI/CD
  - [ ] 13.1 Create validation workflow
    - Create `.github/workflows/validate.yml`
    - Configure format check, validate, and test jobs
    - Configure plan job with PR comment
    - _Requirements: 2.3_
  - [ ] 13.2 Add Infracost integration for cost forecasting
    - Add Infracost setup step to validation workflow
    - Configure cost breakdown generation
    - Post cost estimates as PR comments
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  - [ ] 13.3 Create deploy workflow
    - Create `.github/workflows/deploy.yml`
    - Configure environment selection
    - Configure OIDC authentication
    - _Requirements: 2.3_
  - [ ] 13.4 Create destroy workflow
    - Create `.github/workflows/destroy.yml`
    - Configure confirmation requirement
    - _Requirements: 2.3_

- [ ] 14. Set up testing infrastructure
  - [ ] 14.1 Create tofu test configuration
    - Create `infrastructure/tests/` directory structure
    - Create mock provider configuration for tests
    - _Requirements: 2.1_
  - [ ] 14.2 Create unit tests
    - Test OpenTofu validation
    - Test plan output contains expected resources
    - _Requirements: 2.1_

- [ ] 15. Final checkpoint - Complete validation
  - Run `tofu fmt -check -recursive`
  - Run `tofu validate`
  - Run `tofu test`
  - Ensure all tests pass, ask the user if questions arise

## Notes

- All tasks are required for comprehensive validation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
