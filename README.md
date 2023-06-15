# Minecraft Server Installation Tutorial

- **Jordan Peterson**
- **CS312 System Administration**
- **Final Project Tutorial**
- **Due: 6/14/2023**

## Overview
Utilizing Terraform to automate AWS resources, this repo creates a Docker image running on an EC2 instance that creates and runs a Minecraft server.

## Prerequisties
Before starting this guide, you will need:

* WSL2 on Windows Machines: if you are running on a Windows machine and do not have WSL2 set up follow [Microsoft's Installation Tutorial](https://learn.microsoft.com/en-us/windows/wsl/install)
* An AWS account:  if you don't already have one, follow the [Setting Up Your Environment](https://aws.amazon.com/getting-started/guides/setup-environment/) getting started guide for a quick overview.
* AWS Command Line Interface: if you don't already have this, follow the [Installing AWS CLI Tutorial](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
* Terraform installed: if you don't already have this, follow the [Install Terraform Tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

## 1. Configure Credentials
The following example is for users with the AWS Academy Learner Lab, if you do not have this look online for how to locate your `aws_access_key_id`, `aws_secret_access_key`, and `aws_session_token`.

1. Start your AWS Academy Learned Lab (it must be running for credentials to be initialized).
2. Click on the "AWS Details" tab located in the top right of the Learner Lab page.
3. On your machine, create credential file at `~/.aws/credentials` and copy the credentials into it with the following format: `<var> = <value>`
4. You can also configure the auth variables using the CLI as follows `aws configure set <var> "<value>"` for each of the three variables.

## Create Terraform Project

1. Each Terraform configuration must be in its own working directory. Create a directory for you configuration: `mkdir terraform-instance`.
2. Move to this new directory (`cd terraform-instance`)
3. Create a new file named `main.tf`. After you create this file, open it in your text editor, paste in the configuration below, and save the file. 

```
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
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft Security Group"
  }
}

resource "aws_instance" "minecraft-server" {
  ami                         = "ami-098e42ae54c764c35"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.minecrift-server.id]
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
```

## Apply Terraform Project

1. Run the `terraform fmt` command to format the main.tf (fixes any small formatting errors).
2. Run the `terraform init` command to initialize terraform project.
3. Run the `terraform plan` command to stage changes before deployment.
4. Run the `terraform apply` command and enter "yes" when prompted to `Enter a value` to deploy.
5. Wait until apply is completed and it should output a value for `instance_ip_addr` that you can use to connect to your Minecraft server! (Note: It takes a minute or two after completion for te server to actually start up as it takes some time for it to load the world).