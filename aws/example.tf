variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "local_ip" {}
variable "ssh_key_name" {}
variable "ssh_public_key" {}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

# Destroying does not delete the default vpc.
resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "ssh"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "test" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.ssh_key_name

  tags = {
    Name = "test"
  }

  security_groups = [
    aws_security_group.ssh.name
  ]
}

output "public_ip" {
  value = aws_instance.test.public_ip
}
