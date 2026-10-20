
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_key_pair" "tf_keypair" {
  key_name   = "tf_keypair"
  public_key = file("C:\\sshkey\\tf_keypair.pub")
  tags = {
    Name = "tf_keypair"
  }
}

data "aws_ami" "LatestAmi" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}


resource "aws_vpc" "g2b_KonepVPC" {
  cidr_block           = "172.20.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "g2b_KonepVPC"
  }
}

resource "aws_internet_gateway" "g2b_KonepIGW" {
  vpc_id = aws_vpc.g2b_KonepVPC.id

  tags = {
    Name = "g2b_KonepPublic1Subnet"
  }
}

resource "aws_subnet" "g2b_KonepPublic1Subnet" {
  vpc_id                  = aws_vpc.g2b_KonepVPC.id
  cidr_block              = "172.20.11.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2b_KonepPublic1Subnet"
  }
}

resource "aws_route_table" "g2b_KonepPublic1Routing" {
  depends_on = [aws_internet_gateway.g2b_KonepIGW]
  vpc_id     = aws_vpc.g2b_KonepVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.g2b_KonepIGW.id
  }

  tags = {
    Name = "g2b_KonepPublic1Routing"
  }
}

resource "aws_route_table_association" "g2b_KonepPublic1RouteTableAssociation" {
  subnet_id      = aws_subnet.g2b_KonepPublic1Subnet.id
  route_table_id = aws_route_table.g2b_KonepPublic1Routing.id
}


resource "aws_eip" "g2b_KonepNatGW1EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2b_KonepNatGW1" {
  depends_on    = [aws_internet_gateway.g2b_KonepIGW]
  allocation_id = aws_eip.g2b_KonepNatGW1EIP.id
  subnet_id     = aws_subnet.g2b_KonepPublic1Subnet.id

  tags = {
    Name = "g2b_KonepNatGW1"
  }

}

resource "aws_subnet" "g2b_KonepPrivate1Subnet" {
  vpc_id                  = aws_vpc.g2b_KonepVPC.id
  cidr_block              = "172.20.21.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2b_KonepPrivate1Subnet"
  }
}

resource "aws_route_table" "g2b_KonepPrivate1Routing" {
  depends_on = [aws_nat_gateway.g2b_KonepNatGW1]
  vpc_id     = aws_vpc.g2b_KonepVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.g2b_KonepNatGW1.id
  }

  tags = {
    Name = "g2b_KonepPrivate1Routing"
  }
}

resource "aws_route_table_association" "g2b_KonepPrivate1RouteTableAssociation" {
  subnet_id      = aws_subnet.g2b_KonepPrivate1Subnet.id
  route_table_id = aws_route_table.g2b_KonepPrivate1Routing.id
}


resource "aws_subnet" "g2b_KonepPublic2Subnet" {
  vpc_id                  = aws_vpc.g2b_KonepVPC.id
  cidr_block              = "172.20.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2b_KonepPublic2Subnet"
  }
}

resource "aws_route_table" "g2b_KonepPublic2Routing" {
  depends_on = [aws_internet_gateway.g2b_KonepIGW]
  vpc_id     = aws_vpc.g2b_KonepVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.g2b_KonepIGW.id
  }

  tags = {
    Name = "g2b_KonepPublic2Routing"
  }
}

resource "aws_route_table_association" "g2b_KonepPublic2RouteTableAssociation" {
  subnet_id      = aws_subnet.g2b_KonepPublic2Subnet.id
  route_table_id = aws_route_table.g2b_KonepPublic2Routing.id
}


resource "aws_eip" "g2b_KonepNatGW2EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2b_KonepNatGW2" {
  depends_on    = [aws_internet_gateway.g2b_KonepIGW]
  allocation_id = aws_eip.g2b_KonepNatGW2EIP.id
  subnet_id     = aws_subnet.g2b_KonepPublic2Subnet.id

  tags = {
    Name = "g2b_KonepNatGW2"
  }

}

resource "aws_subnet" "g2b_KonepPrivate2Subnet" {
  vpc_id                  = aws_vpc.g2b_KonepVPC.id
  cidr_block              = "172.20.22.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2b_KonepPrivate2Subnet"
  }
}

resource "aws_route_table" "g2b_KonepPrivate2Routing" {
  depends_on = [aws_nat_gateway.g2b_KonepNatGW2]
  vpc_id     = aws_vpc.g2b_KonepVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.g2b_KonepNatGW2.id
  }

  tags = {
    Name = "g2b_KonepPrivate2Routing"
  }
}

resource "aws_route_table_association" "g2b_KonepPrivate2RouteTableAssociation" {
  subnet_id      = aws_subnet.g2b_KonepPrivate2Subnet.id
  route_table_id = aws_route_table.g2b_KonepPrivate2Routing.id
}

resource "aws_security_group" "g2b_KonepSecugroup" {
  name        = "g2b_KonepSecugroup"
  description = "Permit http,https,ssh"
  vpc_id      = aws_vpc.g2b_KonepVPC.id
  tags = {
    Name = "g2b_KonepSecugroup"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      aws_security_group.g2b_KonepBastionSG.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
