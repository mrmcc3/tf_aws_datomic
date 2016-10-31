variable "aws_region" {
  default = "ap-southeast-2"
}

variable "aws_account" {}

variable "system_name" {
  default = "datomic"
}

variable "datomic_license" {}

variable "peer_ssh_key" {}

variable "peer_ami" {
  default = "ami-6c14310f" # stock ubuntu 14.04 LTS (ap-southeast-2)
}

variable "peer_availability_zones" {
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "peer_instance_type" {
  default = "t2.small"
}

variable "peers" {
  default = "1"
}
variable "wget_user" {

}
variable "wget_pass" {
 
}

variable "transactor_availability_zones" {
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "transactor_instance_type" {
  default = "c3.large"
}

variable "transactor_instance_virtualization_type" {
  default = "hvm"
}

variable "transactors" {
  default = "1"
}

variable "transactor_memory_index_max" {
  default = "512m"
}

variable "transactor_memory_index_threshold" {
  default = "32m"
}

variable "transactor_object_cache_max" {
  default = "1g"
}

variable "transactor_java_opts" {
  default = ""
}

variable "transactor_xmx" {
  default = "2625m"
}

variable "datomic_version" {
  default = "0.9.5390"
}

variable "transactor_deploy_bucket" {
  default = "deploy-a0dbc565-faf2-4760-9b7e-29a8e45f428e"
}

variable "dynamo_read_capacity" {
  default = 50
}

variable "dynamo_write_capacity" {
  default = 50
}
