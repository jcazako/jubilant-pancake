# Feature: llm-inference-service, Property 3: Minimum Instance Guarantee
# Validates: Requirements 3.3
#
# Property: *For any* combination of min_instances and max_instances variables
# where min_instances >= 1, the Auto Scaling Group configuration SHALL have
# min_size >= 1, ensuring at least one instance is always running.

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id           = "ami-12345678"
      name         = "Deep Learning AMI GPU PyTorch 2.0 (Ubuntu 22.04)"
      architecture = "x86_64"
    }
  }
}

# Override for IAM instance profile ARN validation
override_resource {
  target = aws_iam_instance_profile.ec2_profile
  values = {
    arn = "arn:aws:iam::123456789012:instance-profile/test-profile"
  }
}

override_resource {
  target = aws_iam_role.ec2_role
  values = {
    arn = "arn:aws:iam::123456789012:role/test-role"
  }
}

override_resource {
  target = aws_launch_template.gpu_instance
  values = {
    id             = "lt-12345678901234567"
    latest_version = 1
  }
}

override_resource {
  target = aws_autoscaling_policy.scale_up
  values = {
    arn = "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:12345678-1234-1234-1234-123456789012:autoScalingGroupName/test-asg:policyName/scale-up"
  }
}

override_resource {
  target = aws_autoscaling_policy.scale_down
  values = {
    arn = "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:12345678-1234-1234-1234-123456789012:autoScalingGroupName/test-asg:policyName/scale-down"
  }
}

variables {
  environment           = "test"
  instance_type         = "g5.xlarge"
  min_instances         = 1
  max_instances         = 4
  scale_up_threshold    = 70
  scale_down_threshold  = 30
  private_subnet_ids    = ["subnet-12345678", "subnet-87654321"]
  ec2_security_group_id = "sg-12345678"
  target_group_arn      = ""
  log_group_name        = "test-log-group"
  root_volume_size      = 100
  root_volume_type      = "gp3"
}

run "asg_min_size_equals_min_instances_default" {
  command = plan

  module {
    source = "./modules/compute"
  }

  # Verify ASG min_size matches min_instances variable
  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size == 1
    error_message = "ASG min_size must equal min_instances (default: 1)"
  }

  # Verify ASG min_size is at least 1
  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size >= 1
    error_message = "ASG min_size must be at least 1 to ensure service availability"
  }
}

run "asg_min_size_with_min_instances_2" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    min_instances = 2
    max_instances = 6
  }

  # Property test: For any min_instances >= 1, ASG min_size must match
  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size == 2
    error_message = "ASG min_size must equal min_instances when set to 2"
  }

  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size >= 1
    error_message = "ASG min_size must always be at least 1"
  }
}

run "asg_min_size_with_min_instances_3" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    min_instances = 3
    max_instances = 10
  }

  # Property test: For any min_instances >= 1, ASG min_size must match
  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size == 3
    error_message = "ASG min_size must equal min_instances when set to 3"
  }

  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size >= 1
    error_message = "ASG min_size must always be at least 1"
  }
}

run "asg_max_size_respects_max_instances" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    min_instances = 1
    max_instances = 8
  }

  # Verify ASG max_size matches max_instances variable
  assert {
    condition     = aws_autoscaling_group.gpu_asg.max_size == 8
    error_message = "ASG max_size must equal max_instances"
  }

  # Verify max_size >= min_size
  assert {
    condition     = aws_autoscaling_group.gpu_asg.max_size >= aws_autoscaling_group.gpu_asg.min_size
    error_message = "ASG max_size must be greater than or equal to min_size"
  }
}

run "asg_desired_capacity_equals_min_instances" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    min_instances = 2
    max_instances = 4
  }

  # Verify desired_capacity starts at min_instances
  assert {
    condition     = aws_autoscaling_group.gpu_asg.desired_capacity == 2
    error_message = "ASG desired_capacity should equal min_instances on creation"
  }
}

run "asg_min_size_prod_environment" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    environment   = "prod"
    min_instances = 2
    max_instances = 10
  }

  # Property test: For ANY environment, minimum instance guarantee must hold
  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size >= 1
    error_message = "ASG min_size must be at least 1 in prod environment"
  }

  assert {
    condition     = aws_autoscaling_group.gpu_asg.min_size == 2
    error_message = "ASG min_size must equal min_instances in prod environment"
  }
}
