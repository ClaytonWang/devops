variable "cluster_name" {
  description = "cluster name"
}

variable "vpc_id" {
  description = "VPC ID to create cluster in"
}

variable "vpc_subnets" {
  description = "List of VPC subnets to put instances in"
  default     = []
}

variable "image_id" {
  description = "AMI image_id for ECS instance"
  default     = ""
}