# Datomic terraform module

NOTE: this module is meant as an example to show how you can setup a 
basic Datomic system on AWS using terraform.

### Example Usage

```js
module "datomic" {
source = "github.com/mrmcc3/tf_aws_datomic"

  aws_region      = "ap-southeast-2"
  aws_account     = "..."
  system_name     = "mydatomic"
  datomic_version = "0.9.5390"
  datomic_license = "..."

  # peers
  peers                   = 1
  peer_ami                = "ami-6c14310f"
  peer_instance_type      = "t2.small"
  peer_availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  peer_ssh_key            = "..."

  # transactors
  transactors                       = 1
  transactor_ami                    = "ami-c942d9f3" # datomic ami (ap-southeast-2)
  transactor_instance_type          = "c3.large"
  transactor_availability_zones     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  transactor_memory_index_max       = "512m"
  transactor_memory_index_threshold = "32m"
  transactor_object_cache_max       = "1g"
  transactor_java_opts              = ""
  transactor_xmx                    = "2625m"
  transactor_deploy_bucket          = "deploy-a0dbc565-faf2-4760-9b7e-29a8e45f428e"

  # storage
  dynamo_read_capacity  = 10
  dynamo_write_capacity = 10
}

```
