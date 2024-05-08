terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
}

locals {
  name 	       	  = "petclinic"
  dev-server-tag  = "Dev Server of Petclinic"
  keyname         = "ec2-key" # Key name of the SSH Key Pair stored on AWS to use for the instance.
  instancetype    = "t3a.medium"
  ami 	          = "ami-051f8a213df8bc089"


  github_user 	    = "nirgluzman"
  github_repository = "petclinic-microservices-with-db"
  github_token      = "<GitHub Token>"
}

resource "aws_instance" "dev-server" {
  ami                  = local.ami
  instance_type        = local.instancetype
  key_name             = local.keyname
  user_data            = templatefile("${path.module}/script.sh", {
     GITHUB_USER       = local.github_user
     GITHUB_TOKEN      = local.github_token
     GITHUB_REPOSITORY = local.github_repository
  })
  vpc_security_group_ids = [aws_security_group.tf-dev-server-sec-gr.id]
  tags = {
    Name = local.dev-server-tag
  }
}

resource "aws_security_group" "tf-dev-server-sec-gr" {
  name = "${local.name}-dev-server-sec-gr"
  tags = {
    Name = "${local.name}-dev-server-sec-gr"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "dev-server_public_dns" {
  value = aws_instance.dev-server.public_dns
}

output "dev-server_private_dns" {
  value = aws_instance.dev-server.private_dns
}
