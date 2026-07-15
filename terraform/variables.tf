variable "aws_region" { default = "us-east-1" }
variable "master_instance_type" { default = "t3.medium" }
variable "worker_instance_type" { default = "t3.medium" }
variable "worker_count" { default = 2 }
variable "key_name" { type = string }
variable "private_key_path" { type = string }
