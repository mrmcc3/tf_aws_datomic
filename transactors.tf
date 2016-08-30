# transactor role. ec2 instances can assume the role of a transactor
resource "aws_iam_role" "transactor" {
  name = "${var.system_name}_transactors"

  assume_role_policy = <<EOF
{"Version": "2012-10-17",
 "Statement":
 [{"Action": "sts:AssumeRole",
   "Principal": {"Service": "ec2.amazonaws.com"},
   "Effect": "Allow",
   "Sid": ""}]}
EOF
}

# policy with complete access to the dynamodb table
resource "aws_iam_role_policy" "transactor" {
  name = "dynamo_access"
  role = "${aws_iam_role.transactor.id}"

  policy = <<EOF
{"Statement":
 [{"Effect":"Allow",
   "Action":["dynamodb:*"],
   "Resource":"arn:aws:dynamodb:*:${var.aws_account}:table/${aws_dynamodb_table.datomic.name}"}]}
EOF
}

# policy with write access to cloudwatch
resource "aws_iam_role_policy" "transactor_cloudwatch" {
  name = "cloudwatch_access"
  role = "${aws_iam_role.transactor.id}"

  policy = <<EOF
{"Statement":
 [{"Effect":"Allow",
   "Resource":"*",
   "Condition":{"Bool":{"aws:SecureTransport":"true"}},
   "Action": ["cloudwatch:PutMetricData", "cloudwatch:PutMetricDataBatch"]}]}
EOF
}

# s3 bucket for the transactor logs
resource "aws_s3_bucket" "transactor_logs" {
  bucket = "${var.system_name}-transactor-logs"
  force_destroy = true

  lifecycle {
    # prevent_destroy = true
  }
}

# policy with write access to the transactor logs
resource "aws_iam_role_policy" "transactor_logs" {
  name = "s3_logs_access"
  role = "${aws_iam_role.transactor.id}"

  policy = <<EOF
{"Statement":
 [{"Effect": "Allow",
   "Action": ["s3:PutObject"],
   "Resource": ["arn:aws:s3:::${aws_s3_bucket.transactor_logs.id}",
                "arn:aws:s3:::${aws_s3_bucket.transactor_logs.id}/*"]}]}
EOF
}

# instance profile which assumes the transactor role
resource "aws_iam_instance_profile" "transactor" {
  name  = "${var.system_name}_datomic_transactor"
  roles = ["${aws_iam_role.transactor.name}"]
}

# security group for transactor access. (for both peers and transactor)
resource "aws_security_group" "datomic" {
  ingress {
    from_port = 4334
    to_port   = 4334
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# transactor ami
data "aws_ami" "transactor" {
  most_recent = true
  owners      = ["754685078599"]

  filter {
    name   = "name"
    values = ["datomic-transactor-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["${var.transactor_instance_virtualization_type}"]
  }
}

# transactor launch config
resource "aws_launch_configuration" "transactor" {
  name_prefix          = "${var.system_name}-transactor-"
  image_id             = "${data.aws_ami.transactor.id}"
  instance_type        = "${var.transactor_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.transactor.name}"
  security_groups      = ["${aws_security_group.datomic.name}"]
  user_data            = "${data.template_file.transactor_user_data.rendered}"

  ephemeral_block_device {
    device_name  = "/dev/sdb"
    virtual_name = "ephemeral0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# user data template for bootstraping the transactor
data "template_file" "transactor_user_data" {
  template = "${file("${path.module}/scripts/bootstrap-transactor.sh")}"

  vars {
    xmx                    = "${var.transactor_xmx}"
    java_opts              = "${var.transactor_java_opts}"
    datomic_bucket         = "${var.transactor_deploy_bucket}"
    datomic_version        = "${var.datomic_version}"
    aws_region             = "${var.aws_region}"
    transactor_role        = "${aws_iam_role.transactor.name}"
    peer_role              = "${aws_iam_role.peer.name}"
    memory_index_max       = "${var.transactor_memory_index_max}"
    s3_log_bucket          = "${aws_s3_bucket.transactor_logs.id}"
    memory_index_threshold = "${var.transactor_memory_index_threshold}"
    cloudwatch_dimension   = "${var.system_name}"
    object_cache_max       = "${var.transactor_object_cache_max}"
    license-key            = "${var.datomic_license}"
    dynamo_table           = "${aws_dynamodb_table.datomic.name}"
  }
}

# autoscaling group for launching transactors
resource "aws_autoscaling_group" "transactors" {
  availability_zones   = "${var.transactor_availability_zones}"
  name                 = "${var.system_name}_transactors"
  max_size             = "${var.transactors}"
  min_size             = "${var.transactors}"
  launch_configuration = "${aws_launch_configuration.transactor.name}"

  tag {
    key                 = "Name"
    value               = "${var.system_name}"
    propagate_at_launch = true
  }
}
