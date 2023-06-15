terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.2"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

variable "mojang_server_url" {
  type    = string
  default = "https://launcher.mojang.com/v1/objects/c8f83c5655308435b3dcf03c06d9fe8740a77469/server.jar"
}
resource "aws_security_group" "minecraft-server" {
  name        = "minecraft-server"
  description = "Security group for Minecraft server"

  ingress {
    description = "Default port for Minecraft"
    from_port   = "25565"
    to_port     = "25565"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft Security Group"
  }
}

resource "aws_instance" "minecraft-server" {
  ami                         = "ami-098e42ae54c764c35"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.minecraft-server.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum -y update
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-17-amazon-corretto-devel.x86_64
    wget -O server.jar ${var.mojang_server_url}
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    sed -i 's/eula=false/eula/true' eula.txt
    screen -d -m java -Xmx1024M -Xms1024M -jar server.jar nogui
    EOF
  tags = {
    Name = "Minecraft"
  }
}
output "instance_ip_addr" {
  value = aws_instance.minecraft-server.public_ip
}
