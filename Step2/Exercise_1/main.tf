terraform {
  required_version = ">= 1.0.0"
}

# TODO: Designate a cloud provider, region, and credentials
provider "aws" {
  region = "us-east-1"
}

# Define variables for VPC and subnet IDs
variable "vpc_id" {
  description = "vpc-054eb2820aa9ab765"
}

variable "public_subnet_id" {
  description = "subnet-03d000fbf590efd46"
}

# TODO: provision 4 AWS t2.micro EC2 instances named Udacity T2
resource "aws_instance" "t2_micro_instances" {
  count                  = 4
  ami                    = "ami-066784287e358dad1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-09869638307e7fc5c"]
  subnet_id              = var.public_subnet_id

  tags = {
    Name = "Udacity T2-${count.index + 1}"
  }
}

# TODO: provision 2 m4.large EC2 instances named Udacity M4
resource "aws_instance" "m4_large_instances" {
  count                  = 2
  ami                    = "ami-066784287e358dad1"
  instance_type          = "m4.large"
  vpc_security_group_ids = ["sg-09869638307e7fc5c"]
  subnet_id              = var.public_subnet_id

  tags = {
    Name = "Udacity M4-${count.index + 1}"
  }
}