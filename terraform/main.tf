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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "main_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "main_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main_az1" {
  subnet_id      = aws_subnet.main_az1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "main_az2" {
  subnet_id      = aws_subnet.main_az2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2ECRAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecr_policy" {
  name   = "ECRAccessPolicy"
  role   = aws_iam_role.ec2_ecr_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "EC2ECRAccessProfile"
  role = aws_iam_role.ec2_ecr_role.name
}

# Load Balancer
resource "aws_lb" "main" {
  name               = "helloworld-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            = [aws_subnet.main_az1.id, aws_subnet.main_az2.id] 

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "main" {
  name     = "helloworld-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Launch Template (instead of Launch Configuration)
resource "aws_launch_template" "helloworld-app" {
  name          = "helloworld-app-config"
  image_id      = var.ec2_ami
  instance_type = "t2.micro"

  network_interfaces {
    security_groups = [aws_security_group.allow_all.id] 
    associate_public_ip_address = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecr_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y

              # Instala docker e pre-requisitos
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common unzip
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
              sudo apt update -y
              sudo apt install -y docker-ce
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker $USER

              # Instala o AWS CLI
              sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo unzip -q awscliv2.zip
              sudo ./aws/install

              # Executa a app
              sudo aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_uri}
              sudo docker pull ${var.ecr_uri}:latest
              sudo docker run -d -p 80:8080 --name helloworld_app ${var.ecr_uri}:latest
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "helloworld-app" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.main_az1.id, aws_subnet.main_az2.id]
  launch_template {
    id      = aws_launch_template.helloworld-app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.main.arn]
  
  health_check_type          = "ELB"
  health_check_grace_period  = 300
  wait_for_capacity_timeout  = "0"
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
  description = "The DNS name of the ALB"
}