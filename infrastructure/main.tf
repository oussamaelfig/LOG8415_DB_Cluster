# Define the Terraform settings and required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.19.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_ACCESS_KEY
  token      = var.AWS_SESSION_TOKEN
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "key_pair_name" {
  key_name   = var.key_pair_name
  public_key = file("my_terraform_key.pub")
}

# Security group for Gatekeeper with HTTP only
resource "aws_security_group" "gatekeeper_sg" {
  name        = "gatekeeper_security_group"
  description = "Allow HTTP traffic to Gatekeeper"
  vpc_id      = data.aws_vpc.default.id

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

# Security group for Trusted Host (only allows Gatekeeper to connect)
resource "aws_security_group" "trusted_host_sg" {
  name        = "trusted_host_security_group"
  description = "Allow traffic only from Gatekeeper"
  vpc_id      = data.aws_vpc.default.id

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

# Security group for Proxy server
resource "aws_security_group" "proxy_sg" {
  name        = "proxy_security_group"
  description = "Allow Proxy server traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Security group for MySQL servers
resource "aws_security_group" "mysql_sg" {
  name        = "mysql_security_group"
  description = "Allow MySQL traffic within cluster and SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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

# MySQL Cluster Instances (Manager and Workers)
resource "aws_instance" "mysql_manager" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_manager_user_data.sh")

  tags = {
    Name = "MySQL Cluster Manager"
  }
}

resource "aws_instance" "mysql_worker" {
  count           = 2
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.mysql_sg.name]
  user_data       = file("./mysql_worker_user_data.sh")

  tags = {
    Name = "MySQL Cluster Worker ${count.index + 1}"
  }
}

# Proxy Server Instance
resource "aws_instance" "mysql_proxy" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.proxy_sg.name]
  user_data       = file("./mysql_proxy_user_data.sh")

  tags = {
    Name = "MySQL Proxy Server"
  }
}

# Gatekeeper Instance
resource "aws_instance" "gatekeeper" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.gatekeeper_sg.name]
  user_data       = file("./mysql_gatekeeper_user_data.sh")

  tags = {
    Name = "Gatekeeper Server"
  }
}

# Trusted Host Instance
resource "aws_instance" "trusted_host" {
  ami             = "ami-0fc5d935ebf8bc3bc"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.key_pair_name.key_name
  security_groups = [aws_security_group.trusted_host_sg.name]
  user_data       = file("./mysql_trusted_host_user_data.sh")

  tags = {
    Name = "Trusted Host Server"
  }
}

# Outputs
output "mysql_manager_ip" {
  value = aws_instance.mysql_manager.public_ip
}

output "mysql_worker_ips" {
  value = [for instance in aws_instance.mysql_worker : instance.public_ip]
}

output "mysql_proxy_ip" {
  value = aws_instance.mysql_proxy.public_ip
}

output "gatekeeper_ip" {
  value = aws_instance.gatekeeper.public_ip
}

output "trusted_host_ip" {
  value = aws_instance.trusted_host.public_ip
}
