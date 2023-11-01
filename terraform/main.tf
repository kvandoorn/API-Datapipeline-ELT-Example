# Main terraform file for spinning up S3 and Redshift within AWS. 
# Sets permissions, ACLs, and public access block
# Requires .aws/credentials CLI set up

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.23.1"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.aws_region
}

# Configure redshift cluster
resource "aws_redshift_cluster" "redshift" {
  cluster_identifier = "redshift-cluster-pipeline"
  skip_final_snapshot = true 
  master_username    = "awsuser"
  master_password    = var.db_password
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  publicly_accessible = "true"
  iam_roles = [aws_iam_role.redshift_role.arn]
  vpc_security_group_ids = [aws_security_group.sg_redshift.id]
  
}

# Confuge security group for Redshift allowing all inbound/outbound traffic
 resource "aws_security_group" "sg_redshift" {
  name        = "sg_redshift"
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Set S3 Read only access role. This is assigned to Redshift cluster so that it can read data from S3
resource "aws_iam_role" "redshift_role" {
  name = "RedShiftLoadRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

# Create S3 bucket
resource "aws_s3_bucket" "reddit-bucket" {
  bucket = var.s3_bucket
  force_destroy = true 
}

# Set S3 public access for ease of connection point
resource "aws_s3_bucket_public_access_block" "s3_reddit-bucket_public_access_block" {
  bucket = aws_s3_bucket.reddit-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
# # Set access control of bucket to private
# resource "aws_s3_bucket_acl" "s3_reddit-bucket_acl" {
#   bucket = aws_s3_bucket.reddit-bucket.id
#   acl    = "public-read"
# }
