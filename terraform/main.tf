terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "k8s" {
  name_prefix = "lab5-k8s-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress { description = "SSH" from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { description = "K8s API" from_port = 6443 to_port = 6443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { description = "NodePort range" from_port = 30000 to_port = 32767 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  
  # Intra-cluster traffic: all protocols open between cluster members
  ingress { description = "Intra-cluster" from_port = 0 to_port = 0 protocol = "-1" self = true }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }

  tags = { Name = "lab5-k8s-sg" }
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.k8s.id]
  key_name               = var.key_name
  root_block_device { volume_size = 20 }
  tags                   = { Name = "lab5-k8s-master" }
}

resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.k8s.id]
  key_name               = var.key_name
  root_block_device { volume_size = 20 }
  tags                   = { Name = "lab5-k8s-worker-${count.index}" }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
[master]
${aws_instance.master.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no' private_ip=${aws_instance.master.private_ip}

[workers]
%{ for w in aws_instance.worker ~}
${w.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no' private_ip=${w.private_ip}
%{ endfor ~}

[k8s_cluster:children]
master
workers
EOT
}
