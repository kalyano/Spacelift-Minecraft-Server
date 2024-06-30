terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_security_group" "minecraft" {
  ingress {
    description = "Receive SSH from home."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.64.205.197/32"]
  }
  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft"
  }
}

resource "aws_key_pair" "home" {
  key_name   = "Home"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfewD6rb3Y2bZ8FHOHBP/dToEghLKXVZAy7gQG9DWIwu21yY6dn+hMpwSDHXToMPF9yKmk7q6NwePtOQPuEBi8RTTylP8QQduVuRP8f6SRV74+BDH3EfmzQ/cp2lb8ZPTU0PI3YIPqGdJlWrNN7I4aJ9ehy6vlSNm1Y53MHYW279gQHKazZqKnBiVB4d3ohFb/XyLMaygUvFXGSH164zYR6zXSxgvM8YJj8Qo7PuerNAUR9Z4RXOoTDxJ9uz84Iu8XK4tIZxEOHya1lL9TB5xyvASOOwMd1UCDsUSyTITFP+U+Z5KT3+lEOQynnaEiYZk6yzpDdYKZFvQDDC4QZxHZ kalyanoduri1@gmail.com"
}

resource "aws_instance" "minecraft" {
  ami                         = "ami-090a024fa89feca33"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum -y update
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-17-amazon-corretto-devel.x86_64
    wget -O server.jar https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    sed -i 's/eula=false/eula=true/' eula.txt
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    EOF
  tags = {
    Name = "Minecraft"
  }
}

output "instance_ip_addr" {
  value = aws_instance.minecraft.public_ip
}