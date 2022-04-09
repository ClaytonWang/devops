terraform {
  required_version = ">= 0.11"
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.name}"
}

resource "aws_cloudwatch_log_group" "instance" {
  name = "${var.instance_log_group != "" ? var.instance_log_group : format("%s-instance", var.name)}"
  tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}

data "aws_iam_policy_document" "instance_policy" {  
  statement {
    sid = "ecsPolicyForEC2"

    actions = [
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:Submit*",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  } 
}

resource "aws_iam_policy" "instance_policy" {
  name   = "${var.name}-ecs-instance"
  path   = "/"
  policy = "${data.aws_iam_policy_document.instance_policy.json}"
}

resource "aws_iam_role" "instance" {
  name = "${var.name}-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "instance_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "${aws_iam_policy.instance_policy.arn}"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-instance-profile"
  role = "${aws_iam_role.instance.name}"
}

resource "aws_security_group" "instance" {
  name        = "${var.name}-container-instance"
  description = "Security Group managed by Terraform"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(var.tags, map("Name", format("%s-container-instance", var.name)))}"
}

resource "aws_security_group_rule" "instance_out_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instance.id}"
}
resource "aws_security_group_rule" "instance_in_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.instance.id}"
}
resource "aws_security_group_rule" "self_reference" {
    type = "ingress"
    self = true
    from_port = 0
    to_port = 0
    protocol = -1
    security_group_id = "${aws_security_group.instance.id}"
}
data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"

  vars = {
    additional_user_data_script = "${var.additional_user_data_script}"
    ecs_cluster                 = "${aws_ecs_cluster.ecs.name}"
    log_group                   = "${aws_cloudwatch_log_group.instance.name}"
  }
}

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# resource "aws_key_pair" "user" {
#   count      = "${var.instance_keypair != "" ? 0 : 1}"
#   key_name   = "${var.name}"
#   public_key = "${file("~/.ssh/id_rsa.pub")}"
# }

resource "aws_launch_configuration" "instance" {
  name_prefix          = "${var.name}-lc"
  image_id             = "${var.image_id != "" ? var.image_id : data.aws_ami.ecs.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.instance.name}"
  user_data            = "${data.template_file.user_data.rendered}"
  security_groups      = ["${aws_security_group.instance.id}"]
  # key_name             = "${var.instance_keypair != "" ? var.instance_keypair : element(concat(aws_key_pair.user.*.key_name, list("")), 0)}"

  root_block_device {
    volume_size = "${var.instance_root_volume_size}"
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "${var.name}-asg"

  launch_configuration = "${aws_launch_configuration.instance.name}"
  vpc_zone_identifier  = ["${var.vpc_subnets}"]
  max_size             = "${var.asg_max_size}"
  min_size             = "${var.asg_min_size}"
  desired_capacity     = "${var.asg_desired_size}"

  health_check_grace_period = 300
  health_check_type         = "EC2"

  lifecycle {
    create_before_destroy = true
  }
  tags=[
    {
      "key"="AssetID"
      "value"="2703"
      "propagate_at_launch" = true
    },
    {
      "key"="AssetName"
      "value"="DAMO"
      "propagate_at_launch" = true
    },
    {
      "key"="AssetProgram"
      "value"="New Lexis - Content Fabrication Systems"
      "propagate_at_launch" = true
    },
    {
      "key"="AssetPurpose"
      "value"="APAC AI Content Automation is an AI tool for content Editors in US."
      "propagate_at_launch" = true
    },
    {
      "key"="AssetSchedule"
      "value"="FALSE"
      "propagate_at_launch" = true
    },
    {
      "key"="AssetGroup"
      "value"="${var.name}-asg"
      "propagate_at_launch" = true
    },
    {
      "key"="Name"
      "value"="${var.name}-asg"
      "propagate_at_launch" = true
    },
    {
      "key"="JoinDomain"
      "value"="TURE"
      "propagate_at_launch" = true
    },

  ]
}