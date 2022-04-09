provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ssm_parameter" "data_lake_x_api_key" {
  name = "/DAMO/${var.environment_name}/damo_api/data_lake_x_api_key"
}
data "aws_ssm_parameter" "mysql_pwd" {
  name = "/DAMO/${var.environment_name}/damo_api/mysql_pwd"
}


resource "aws_ecs_task_definition" "app" {
  family = "damo_api"

  container_definitions = <<EOF
[
  {
    "name": "damo_api",
    "image": "${var.image_id}",
    "essential": true,    
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "damm_api",
        "awslogs-region": "$${AWS::Region}"
      }
    },
    "memoryReservation": 1000,
    "environment": [
      {
          'name': 'damo_env',
          'value': ${var.environment_name}
      },
      {
          'name': 'data_lake_x_api_key_${var.environment_name}',
          'value': ${data.aws_ssm_parameter.data_lake_x_api_key.value}
      },
      {
          'name': 'mysql_pwd_${var.environment_name}',
          'value': ${data.aws_ssm_parameter.mysql_pwd.value}
      }
    ]
  }
]
EOF
}

module "ecs_service_app" {
  source = "../modules/service"

  name                 = "damo_api"
  # alb_target_group_arn = "${module.alb.target_group_arn}"
  cluster              = "DAMO-Cluster"
  container_name       = "damo_api"
  container_port       = "80"
  log_groups           = ["damo-damo_api"]
  task_definition_arn  = "${aws_ecs_task_definition.app.arn}"

  tags = {
    Owner       = "user"
    Environment = "me"
  }
}