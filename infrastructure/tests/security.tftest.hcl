# Feature: llm-inference-service, Property 5: Security Group Least Privilege
# Validates: Requirements 6.4
#
# Property: *For any* security group configuration, ingress rules from 0.0.0.0/0
# SHALL only allow port 443 (HTTPS), and all other ingress SHALL be restricted
# to VPC CIDR or specific security group references.

mock_provider "aws" {}

variables {
  environment          = "test"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  tags                 = {}
}

run "alb_security_group_allows_only_https_from_internet" {
  command = plan

  module {
    source = "./modules/networking"
  }

  # Verify ALB security group has exactly one ingress rule
  assert {
    condition     = length(aws_security_group.alb.ingress) == 1
    error_message = "ALB security group should have exactly one ingress rule"
  }

  # Verify the ingress rule allows only port 443 from 0.0.0.0/0
  # Using one_of to extract the single element from the set
  assert {
    condition = alltrue([
      for rule in aws_security_group.alb.ingress :
      rule.from_port == 443 &&
      rule.to_port == 443 &&
      rule.protocol == "tcp" &&
      contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "ALB security group ingress from internet must only allow HTTPS (port 443)"
  }
}

run "ec2_security_group_no_direct_internet_ingress" {
  command = plan

  module {
    source = "./modules/networking"
  }

  # Verify EC2 security group does NOT allow ingress from 0.0.0.0/0
  assert {
    condition = alltrue([
      for rule in aws_security_group.ec2.ingress :
      !contains(coalesce(rule.cidr_blocks, []), "0.0.0.0/0")
    ])
    error_message = "EC2 security group must not allow any ingress from 0.0.0.0/0 (internet)"
  }

  # Verify EC2 security group only allows traffic via security group reference
  assert {
    condition = alltrue([
      for rule in aws_security_group.ec2.ingress :
      length(rule.security_groups) > 0
    ])
    error_message = "EC2 security group ingress must reference ALB security group, not CIDR blocks"
  }

  # Verify EC2 ingress is restricted to port 8000 (vLLM)
  assert {
    condition = alltrue([
      for rule in aws_security_group.ec2.ingress :
      rule.from_port == 8000 && rule.to_port == 8000
    ])
    error_message = "EC2 security group ingress must only allow port 8000 (vLLM)"
  }
}

run "security_group_least_privilege_with_prod_environment" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment = "prod"
  }

  # Property test: For ANY environment, the security constraints must hold
  # ALB allows only HTTPS (443) from internet
  assert {
    condition = alltrue([
      for rule in aws_security_group.alb.ingress :
      rule.from_port == 443 && rule.to_port == 443
    ])
    error_message = "ALB security group must only allow port 443 from internet regardless of environment"
  }

  # EC2 has no direct internet access
  assert {
    condition = alltrue([
      for rule in aws_security_group.ec2.ingress :
      !contains(coalesce(rule.cidr_blocks, []), "0.0.0.0/0")
    ])
    error_message = "EC2 security group must not allow internet ingress regardless of environment"
  }
}

run "security_group_least_privilege_with_staging_environment" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment = "staging"
  }

  # Property test: For ANY environment, the security constraints must hold
  # ALB allows only HTTPS (443) from internet
  assert {
    condition = alltrue([
      for rule in aws_security_group.alb.ingress :
      rule.from_port == 443 && rule.to_port == 443
    ])
    error_message = "ALB security group must only allow port 443 from internet regardless of environment"
  }

  # EC2 has no direct internet access
  assert {
    condition = alltrue([
      for rule in aws_security_group.ec2.ingress :
      !contains(coalesce(rule.cidr_blocks, []), "0.0.0.0/0")
    ])
    error_message = "EC2 security group must not allow internet ingress regardless of environment"
  }
}
