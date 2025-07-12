variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "public_subnet_cidr_1" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  type        = string
  default     = "us-east-1b"
}
