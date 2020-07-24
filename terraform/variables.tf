variable "suffix" {
  default = "RaB"
}

variable "user_id" {
  default = "rabru"
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_az" {
  default = "eu-central-1a"
}

variable "aws_az1" {
  default = "eu-central-1b"
}

variable "management_subnet_cidr" {
  description = "CIDR for the Management subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.3.0/24"
}

variable "cluster-name" {
  default = "RaB-terraform-eks-demo"
  type    = string
}

variable "key_name" {
  default = "RaB_AWS_public"
  type    = string
}
