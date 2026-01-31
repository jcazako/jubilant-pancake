# OpenTofu Backend Configuration
# Remote state storage in S3 with DynamoDB locking
# Requirements: 2.5

terraform {
  backend "s3" {
    bucket         = "llm-inference-tfstate"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "llm-inference-tfstate-lock"
  }
}

# Note: The S3 bucket and DynamoDB table must be created before initializing
# the backend. Use the bootstrap configuration below to create them:
#
# Bootstrap resources (run separately or create manually):
#
# resource "aws_s3_bucket" "tfstate" {
#   bucket = "llm-inference-tfstate"
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }
#
# resource "aws_s3_bucket_versioning" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.id
#
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
#
# resource "aws_dynamodb_table" "tfstate_lock" {
#   name         = "llm-inference-tfstate-lock"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }
