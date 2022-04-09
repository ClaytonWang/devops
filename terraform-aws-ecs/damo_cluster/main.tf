provider "aws" {
  region = "ap-southeast-1"
}

module "ecs_cluster" {
  source = "../modules/cluster"

  name        = "var.cluster_name"
  image_id    = "var.image_id"
  vpc_id      = "var.vpc_id"
  vpc_subnets = "var.vpc_subnets"
  
  tags = {
    Owner       = "user"
    Environment = "me"
  }
}