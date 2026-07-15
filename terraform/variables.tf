variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "master_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "key_name" {
  type = string
}

variable "private_key_path" {
  type = string
}
