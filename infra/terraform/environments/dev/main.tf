
resource "aws_key_pair" "g2b_konep_keypair" {
  key_name   = "${local.g2b_konep_name_prefix}-keypair"
  public_key = file("${path.module}/keys/tf_keypair.pub")

  tags = local.g2b_konep_common_tags
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


resource "aws_vpc" "g2bkonepVPC" {
  cidr_block           = "172.20.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "g2bkonepVPC"
  }
}

resource "aws_internet_gateway" "g2bkonepIGW" {
  vpc_id = aws_vpc.g2bkonepVPC.id

  tags = {
    Name = "g2bkonepPublic1Subnet"
  }
}

resource "aws_subnet" "g2bkonepPublic1Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.11.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2bkonepPublic1Subnet"
  }
}

resource "aws_route_table" "g2bkonepPublic1Routing" {
  depends_on = [aws_internet_gateway.g2bkonepIGW]
  vpc_id     = aws_vpc.g2bkonepVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.g2bkonepIGW.id
  }

  tags = {
    Name = "g2bkonepPublic1Routing"
  }
}

resource "aws_route_table_association" "g2bkonepPublic1RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPublic1Subnet.id
  route_table_id = aws_route_table.g2bkonepPublic1Routing.id
}


resource "aws_eip" "g2bkonepNatGW1EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2bkonepNatGW1" {
  depends_on    = [aws_internet_gateway.g2bkonepIGW]
  allocation_id = aws_eip.g2bkonepNatGW1EIP.id
  subnet_id     = aws_subnet.g2bkonepPublic1Subnet.id

  tags = {
    Name = "g2bkonepNatGW1"
  }

}

resource "aws_subnet" "g2bkonepPrivate1Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.21.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2bkonepPrivate1Subnet"
  }
}

resource "aws_route_table" "g2bkonepPrivate1Routing" {
  depends_on = [aws_nat_gateway.g2bkonepNatGW1]
  vpc_id     = aws_vpc.g2bkonepVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.g2bkonepNatGW1.id
  }

  tags = {
    Name = "g2bkonepPrivate1Routing"
  }
}

resource "aws_route_table_association" "g2bkonepPrivate1RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPrivate1Subnet.id
  route_table_id = aws_route_table.g2bkonepPrivate1Routing.id
}


resource "aws_subnet" "g2bkonepPublic2Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2bkonepPublic2Subnet"
  }
}

resource "aws_route_table" "g2bkonepPublic2Routing" {
  depends_on = [aws_internet_gateway.g2bkonepIGW]
  vpc_id     = aws_vpc.g2bkonepVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.g2bkonepIGW.id
  }

  tags = {
    Name = "g2bkonepPublic2Routing"
  }
}

resource "aws_route_table_association" "g2bkonepPublic2RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPublic2Subnet.id
  route_table_id = aws_route_table.g2bkonepPublic2Routing.id
}


resource "aws_eip" "g2bkonepNatGW2EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2bkonepNatGW2" {
  depends_on    = [aws_internet_gateway.g2bkonepIGW]
  allocation_id = aws_eip.g2bkonepNatGW2EIP.id
  subnet_id     = aws_subnet.g2bkonepPublic2Subnet.id

  tags = {
    Name = "g2bkonepNatGW2"
  }

}

resource "aws_subnet" "g2bkonepPrivate2Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.22.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2bkonepPrivate2Subnet"
  }
}

resource "aws_route_table" "g2bkonepPrivate2Routing" {
  depends_on = [aws_nat_gateway.g2bkonepNatGW2]
  vpc_id     = aws_vpc.g2bkonepVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.g2bkonepNatGW2.id
  }

  tags = {
    Name = "g2bkonepPrivate2Routing"
  }
}

resource "aws_route_table_association" "g2bkonepPrivate2RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPrivate2Subnet.id
  route_table_id = aws_route_table.g2bkonepPrivate2Routing.id
}

resource "aws_security_group" "g2bkonepSecugroup" {
  name        = "g2bkonepSecugroup"
  description = "Permit http,https,ssh"
  vpc_id      = aws_vpc.g2bkonepVPC.id
  tags = {
    Name = "g2bkonepSecugroup"
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
      aws_security_group.g2bkonepBastionSG.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
