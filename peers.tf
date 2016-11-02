# peer role. ec2 instances can assume the role of a peer
resource "aws_iam_role" "peer" {
  name = "${var.system_name}_peer"

  assume_role_policy = <<EOF
{"Version": "2012-10-17",
 "Statement":
 [{"Sid": "",
   "Effect": "Allow",
   "Principal": {"Service": "ec2.amazonaws.com"},
   "Action": "sts:AssumeRole"}]}
EOF
}

# this policy allows read access to the dynamo table
resource "aws_iam_role_policy" "peer_dynamo_access" {
  name = "dynamo_access"
  role = "${aws_iam_role.peer.id}"

  policy = <<EOF
{"Statement":
 [{"Effect":"Allow",
   "Action":
   ["dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Scan", "dynamodb:Query"],
   "Resource":"arn:aws:dynamodb:*:${var.aws_account}:table/${aws_dynamodb_table.datomic.name}"}]}
EOF
}

# this policy allows peers to put to CloudWatch Logs
resource "aws_iam_role_policy" "peer_cloudwatch_logs" {
  name = "cloudwatch_logs"
  role = "${aws_iam_role.peer.id}"

  policy = <<EOF
{"Version": "2012-10-17",
 "Statement":
 [{"Effect": "Allow",
   "Action":
   ["logs:CreateLogGroup", "logs:CreateLogStream",
    "logs:PutLogEvents", "logs:DescribeLogStreams"],
   "Resource": ["arn:aws:logs:*:*:*"]}]}
EOF
}

# instance profile which assumes the peer role
resource "aws_iam_instance_profile" "peer" {
  name  = "${var.system_name}_peer"
  roles = ["${aws_iam_role.peer.name}"]
}

# security group for ssh access (from anywhere)
resource "aws_security_group" "ssh" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# key pair for ssh access to peers
resource "aws_key_pair" "peer" {
  key_name   = "${var.system_name}-peer-key"
  public_key = "${var.peer_ssh_key}"
}


# user data template for bootstraping the peer
data "template_file" "peer_user_data" {
  template = "${file("${path.module}/scripts/bootstrap-peer.sh")}"

  vars {
    xmx                    = "${var.transactor_xmx}"
    java_opts              = "${var.transactor_java_opts}"
    datomic_bucket         = "${var.transactor_deploy_bucket}"
    datomic_version        = "${var.datomic_version}"
    wget_user              = "${var.wget_user}"
    wget_pass              = "${var.wget_pass}"
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

# autoscaling group for launching peers
resource "aws_autoscaling_group" "peers" {
  availability_zones   = "${var.peer_availability_zones}"
  name                 = "${var.system_name}_peers"
  max_size             = "${var.peers}"
  min_size             = "${var.peers}"
  launch_configuration = "${aws_launch_configuration.peer.name}"
}
# peer launch configuration
resource "aws_launch_configuration" "peer" {
  name_prefix          = "${var.system_name}-peer-"
  image_id             = "${var.peer_ami}"
  instance_type        = "${var.peer_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.peer.name}"
  security_groups      = ["${aws_security_group.ssh.name}", "${aws_security_group.datomic.name}"]
  user_data            = "${data.template_file.peer_user_data.rendered}"
  key_name             = "${aws_key_pair.peer.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_instance" "peer_instance" {
    ami                         = "${var.peer_ami}"
    instance_type               = "${var.peer_instance_type}"
    subnet_id                   = "${var.peer_subnet_id}"
    key_name                    = "${aws_key_pair.peer.key_name}"
    vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.datomic.id}"]
    associate_public_ip_address = "${var.peer_public_ip}"
    monitoring                  = "${var.peer_monitoring}"
    iam_instance_profile = "${aws_iam_instance_profile.peer.name}"
    user_data            = "${data.template_file.peer_user_data.rendered}"

    tags {
        Environment = "${var.system_name}"
        Role = "Datomic Peer"
        Name = "${var.system_name} - Peer"


    }
}

# outputs
output "peer_instance_private_ip" {
  value = "${aws_instance.peer_instance.private_ip}"
}

output "peer_iam_role" {
  value = "${aws_iam_role.peer.id}"
}

output "peer_iam_role_arn" {
  value = "${aws_iam_role.peer.arn}"
}
