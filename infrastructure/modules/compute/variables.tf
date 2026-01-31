# Compute module input variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for GPU instances"
  type        = string
  default     = "g5.xlarge"
}

variable "min_instances" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_instances >= 1
    error_message = "Minimum instances must be at least 1 to ensure service availability."
  }
}

variable "max_instances" {
  description = "Maximum number of instances in ASG"
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
}

variable "scale_down_threshold" {
  description = "GPU utilization percentage to trigger scale down"
  type        = number
  default     = 30
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ASG"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group for ALB attachment"
  type        = string
  default     = ""
}

variable "log_group_name" {
  description = "CloudWatch log group name for vLLM logs"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Type of root EBS volume"
  type        = string
  default     = "gp3"
}
