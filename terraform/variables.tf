variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # change to your preferred region
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "public_subnet_az1_cidr" {
  type = string
}

variable "public_subnet_az2_cidr" {
  type = string
}
