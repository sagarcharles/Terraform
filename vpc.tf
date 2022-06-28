provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIA2ECE5ACKKI2NAJ5Q"
  secret_key = "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"
}



resource "aws_key_pair" "test" {
  key_name   = "testkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqzZbaRfZrK/MLJmbmHs4NCROUujN7UNA7q3hac5zsg3AET8i+u+mAMEyc0sBGKmpXN56DXf8aSGCorvXW2sAQc2CmjA2Z5X1a1ILk2yycQBUpoRQvqSQRh2oDDruL/d9jqqODmvYiocZ1p5ngE1WC1Z24twryakblVayJILsAbiuiCkJIw3TYJPIutxB2rH6bW0+eOsfg+YyUpl206WLwZZO6KlVgBBQp1z4JUBy46lXOJ0g/AW3HrZi3WuS/nBpLdPXqWUr9Ta5Vsx/t+6LNN+gGU9CXrWheTDmGP7FGuyxXVBJ2XyojEsNtfDrLX6BO0ac71JVC3ajbnZOYMSLzV149Yz2zaTi7N6axpIR8yvVzc5mi8RwAXgW1qHQP6xNi/CXR+eP0l0y6EsIo4JdNl5NInM1jHHX2KV+DDT6s2RIyK69CZTinvr+MiX3TNiv0U4Hhy2GOhpXX+wD3ngv9W+CQCrDLhGPCDSWGpWWmwQM/ugNUX3dkD4Xh22Ylgo0= paradox@DESKTOP-22T5S6J"
}


resource "aws_eip" "natgwip" {
  vpc      = true
}

resource "aws_vpc" "projectXvpc" {
  cidr_block       = "172.20.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "projectXvpc"
  }
}


resource "aws_subnet" "projectX-public-subnet" {
  vpc_id     = aws_vpc.projectXvpc.id
  cidr_block = "172.20.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}


resource "aws_subnet" "projectX-private-subnet" {
  vpc_id     = aws_vpc.projectXvpc.id
  cidr_block = "172.20.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.natgwip.id
  subnet_id     = aws_subnet.projectX-public-subnet.id

  tags = {
    Name = "gw-NAT"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.projectXvpc.id

  tags = {
    Name = "igw"
  }
}


resource "aws_route_table" "projectXvpc-public-rt" {
  vpc_id = aws_vpc.projectXvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "projectXvpc-private-rt" {
  vpc_id = aws_vpc.projectXvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "private-rt"
  }
}


resource "aws_security_group" "projectXrules" {
  name        = "projectXrules"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.projectXvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "projectXrules"
  }
}

resource "aws_eip" "instance" {
  instance = aws_instance.webserver.id
  vpc      = true
}


resource "aws_instance" "webserver" {
  ami           = "ami-0851b76e8b1bce90b"
  instance_type = "t2.micro"
  key_name      = "testkey" 
  subnet_id     = aws_subnet.projectX-public-subnet.id
  vpc_security_group_ids   = [aws_security_group.projectXrules.id]  

  tags = {
    Name = "webserver"
  }
}


resource "aws_instance" "DB" {
  ami           = "ami-0851b76e8b1bce90b"
  instance_type = "t2.micro"
  key_name      = "testkey" 
  subnet_id     = aws_subnet.projectX-private-subnet.id
  vpc_security_group_ids   = [aws_security_group.projectXrules.id]  

  tags = {
    Name = "DB"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.projectX-public-subnet.id
  route_table_id = aws_route_table.projectXvpc-public-rt.id
}