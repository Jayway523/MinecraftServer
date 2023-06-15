terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.2"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

variable "mojang_server_url" {
  type    = string
  default = "https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar"
}
resource "aws_security_group" "minecraft-server" {
  name        = "minecraft-server"
  description = "Security group for Minecraft server"

  ingress {
    description = "Default port for Minecraft"
    from_port   = 25565
    to_port     = 25565
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
  tags = {
    Name = "Minecraft Security Group"
  }
}
resource "tls_private_key" "minecraft_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft_key"
  public_key = tls_private_key.minecraft_key.public_key_openssh

}

resource "aws_instance" "minecraft-server" {
  ami                         = "ami-03f65b8614a860c29"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.minecraft_key.key_name
  vpc_security_group_ids      = [aws_security_group.minecraft-server.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo add-apt-repository ppa:openjdk-r/ppa 
    sudo apt install openjdk-17-jre-headless
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
