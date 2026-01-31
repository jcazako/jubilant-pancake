# Input variables for LLM Inference Service

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "model_name" {
  description = "HuggingFace model identifier"
  type        = string
  default     = "microsoft/Phi-3-mini-4k-instruct"
}

variable "instance_type" {
  description = "GPU instance type"
  type        = string
  default     = "g5.xlarge"
}

variable "min_instances" {
  description = "Minimum ASG capacity"
  type        = number
  default     = 1
  validation {
    condition     = var.min_instances >= 1
    error_message = "Minimum instances must be at least 1."
  }
}

variable "max_instances" {
  description = "Maximum ASG capacity"
  type        = number
  default     = 4
  validation {
    condition     = var.max_instances >= 1
    error_message = "Maximum instances must be at least 1."
  }
}

variable "scale_up_threshold" {
  description = "GPU utilization percentage to trigger scale up"
  type        = number
  default     = 70
  validation {
    condition     = var.scale_up_threshold > 0 && var.scale_up_threshold <= 100
    error_message = "Scale up threshold must be between 1 and 100."
  }
}


variable "scale_down_threshold" {
  description = "GPU utilization percentage to trigger scale down"
  type        = number
  default     = 30
  validation {
    condition     = var.scale_down_threshold > 0 && var.scale_down_threshold <= 100
    error_message = "Scale down threshold must be between 1 and 100."
  }
}

variable "rate_limit_per_ip" {
  description = "API rate limit per IP per minute"
  type        = number
  default     = 100
  validation {
    condition     = var.rate_limit_per_ip > 0
    error_message = "Rate limit must be greater than 0."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for API (optional)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "enable_api_key" {
  description = "Enable API key authentication for inference requests"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_days)
    error_message = "Retention days must be a valid CloudWatch retention period."
  }
}
