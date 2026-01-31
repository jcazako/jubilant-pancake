# Compute module outputs

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.gpu_asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.gpu_asg.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.gpu_instance.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.gpu_instance.latest_version
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}
