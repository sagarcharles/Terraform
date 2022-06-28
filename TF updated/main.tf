provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAWDWLKZNIJFUNTUEA"
  secret_key = "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"
}


resource "aws_instance" "newwebserver" {
  ami           = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  key_name      = "newkey" 
  count         =  "1"
  vpc_security_group_ids = [aws_security_group.globalSG.id]

  tags = {
    Name = "newwebserver"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "globalSG" {
  name        = "globalSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "globalSG"
  }
}


data "aws_key_pair" "newkey" {
  key_name   = "newkey"
}