# Compute module - EC2, ASG, Launch Template

# Data source for AWS Deep Learning AMI
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning AMI GPU PyTorch * (Ubuntu 22.04) *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-llm-inference-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-llm-inference-ec2-role"
    Environment = var.environment
  }
}

# IAM Policy for CloudWatch and ECR access
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.environment}-llm-inference-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SSM managed policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-llm-inference-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "${var.environment}-llm-inference-ec2-profile"
    Environment = var.environment
  }
}

# Launch Template for GPU instances
resource "aws_launch_template" "gpu_instance" {
  name_prefix   = "${var.environment}-llm-inference-"
  image_id      = data.aws_ami.deep_learning.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    log_group_name = var.log_group_name
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-llm-inference"
      Environment = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "${var.environment}-llm-inference-volume"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.environment}-llm-inference-launch-template"
    Environment = var.environment
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "gpu_asg" {
  name                = "${var.environment}-llm-inference-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.min_instances

  launch_template {
    id      = aws_launch_template.gpu_instance.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Target group attachment handled by aws_autoscaling_attachment resource

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-llm-inference"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target group attachment
resource "aws_autoscaling_attachment" "asg_attachment" {
  count                  = var.target_group_arn != "" ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gpu_asg.name
  lb_target_group_arn    = var.target_group_arn
}

# Scale Up Policy - GPU utilization > 70%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-llm-inference-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.gpu_asg.name
}

# CloudWatch Alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "gpu_high" {
  alarm_name          = "${var.environment}-llm-inference-gpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "utilization_gpu"
  namespace           = "LLMInference"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_threshold
  alarm_description   = "Scale up when GPU utilization exceeds ${var.scale_up_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.gpu_asg.name
  }

  tags = {
    Name        = "${var.environment}-llm-inference-gpu-high-alarm"
    Environment = var.environment
  }
}

# Scale Down Policy - GPU utilization < 30%
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-llm-inference-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = aws_autoscaling_group.gpu_asg.name
}

# CloudWatch Alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "gpu_low" {
  alarm_name          = "${var.environment}-llm-inference-gpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 10
  metric_name         = "utilization_gpu"
  namespace           = "LLMInference"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_threshold
  alarm_description   = "Scale down when GPU utilization falls below ${var.scale_down_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.gpu_asg.name
  }

  tags = {
    Name        = "${var.environment}-llm-inference-gpu-low-alarm"
    Environment = var.environment
  }
}
