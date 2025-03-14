terraform {
  backend "s3" {
    bucket = "zavalik-terraformstate"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_s3_object" "ssh_key" {
  bucket = "zavalik-terraformstate"
  key    = "ssh/id_rsa.pub"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "my-ssh-key"
  public_key = data.aws_s3_object.ssh_key.body
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "main-subnet"
  }
}

# Security Group to allow SSH and HTTP access
resource "aws_security_group" "allow_all" {
  name_prefix = "allow_all"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance with SSH key and VPC
resource "aws_instance" "helloworld_app" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.allow_all.name]
  
  key_name = aws_key_pair.ssh_key.key_name
  
  # Associate the instance with the created subnet
  associate_public_ip_address = true
  
  user_data = <<-EOF
              #!/bin/bash
              # Garante o Docker instalado
              sudo apt update -y
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt update -y
              sudo apt install -y docker-ce
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker $USER
              # Executa a app
              docker pull ${var.ecr_uri}:latest
              docker run -d -p 80:80 --name helloworld_app ${var.ecr_uri}:latest
              EOF
}

# Output the public IP for SSH access
output "instance_public_ip" {
  value = aws_instance.helloworld_app.public_ip
}