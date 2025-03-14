provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "state/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_security_group" "allow_all" {
  name_prefix = "allow_all"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "helloworld_app" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_all.name]
  
  user_data = <<-EOF
              #!/bin/bash
              docker pull ${var.ecr_uri}:latest
              docker run -d -p 80:80 --name helloworld_app ${var.ecr_uri}:latest
              EOF
}
