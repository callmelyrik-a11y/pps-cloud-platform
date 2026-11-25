
# ============================================================
# G2B KONEP - Branch Office Infrastructure
# VPC: 172.20.0.0/16
# Region: ap-northeast-2
#
# Routing:
# Private A -> NAT GW 1
# Private B -> NAT GW 2
# Private A/B -> Shared EKS VPC via existing Peering routes
# ============================================================

# ============================================================
# 1. EC2 Key Pair
# ============================================================

resource "aws_key_pair" "g2b_konep_keypair" {
  key_name = "g2b-konep-keypair"

  public_key = file("${path.module}/key/tf_keypair.pub")

  tags = {
    Name = "g2b-konep-keypair"
  }
}

# ============================================================
# 2. Ubuntu 24.04 LTS - EKS Optimized AMI 조회
# ============================================================

data "aws_ssm_parameter" "ubuntu_eks_ami" {
  name = "/aws/service/canonical/ubuntu/eks/24.04/${var.cluster_version}/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ============================================================
# 3. EKS Worker Node Launch Template
# ============================================================

resource "aws_launch_template" "eks_ubuntu" {
  name_prefix = "g2b-konep-ubuntu-"

  # 위에서 조회한 Ubuntu AMI ID 참조
  image_id = data.aws_ssm_parameter.ubuntu_eks_ami.value

  update_default_version = true

  # EKS Cluster 연결 스크립트
  user_data = base64encode(
    templatefile("${path.module}/script.sh.tftpl", {
      cluster_name = aws_eks_cluster.g2b_konep_eks.name

      cluster_endpoint = aws_eks_cluster.g2b_konep_eks.endpoint

      cluster_ca = aws_eks_cluster.g2b_konep_eks.certificate_authority[0].data
    })
  )

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 40
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # EC2 Instance Metadata 보안 설정
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = local.g2b_konep_common_tags
}

# ============================================================
# 4. Branch VPC
# ============================================================

resource "aws_vpc" "g2bkonepVPC" {
  cidr_block           = "172.20.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "g2bkonepVPC"
  }
}

# ============================================================
# 5. Internet Gateway
# ============================================================

resource "aws_internet_gateway" "g2bkonepIGW" {
  vpc_id = aws_vpc.g2bkonepVPC.id

  tags = {
    Name = "g2bkonepPublic1Subnet"
  }
}

# ============================================================
# 6. Public Subnet A
# ============================================================

resource "aws_subnet" "g2bkonepPublic1Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.11.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2bkonepPublic1Subnet"
  }
}

# ============================================================
# 7. Public Route Table A
# ============================================================

resource "aws_route_table" "g2bkonepPublic1Routing" {
  depends_on = [
    aws_internet_gateway.g2bkonepIGW
  ]

  vpc_id = aws_vpc.g2bkonepVPC.id

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

# ============================================================
# 8. NAT Gateway A
# ============================================================

resource "aws_eip" "g2bkonepNatGW1EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2bkonepNatGW1" {
  depends_on = [
    aws_internet_gateway.g2bkonepIGW
  ]

  allocation_id = aws_eip.g2bkonepNatGW1EIP.id
  subnet_id     = aws_subnet.g2bkonepPublic1Subnet.id

  tags = {
    Name = "g2bkonepNatGW1"
  }
}

# ============================================================
# 9. Private Subnet A
# ============================================================

resource "aws_subnet" "g2bkonepPrivate1Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.21.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2bkonepPrivate1Subnet"
  }
}

# ============================================================
# 10. Private Route Table A
#
# NAT / Peering routes are managed separately.
# ============================================================

resource "aws_route_table" "g2bkonepPrivate1Routing" {
  vpc_id = aws_vpc.g2bkonepVPC.id

  tags = {
    Name = "g2bkonepPrivate1Routing"
  }
}

# ============================================================
# 11. Private A -> NAT Gateway A
# ============================================================

resource "aws_route" "g2b_konep_branch_nat_a" {
  route_table_id = aws_route_table.g2bkonepPrivate1Routing.id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.g2bkonepNatGW1.id
}

# ============================================================
# 12. Private Route Table Association A
# ============================================================

resource "aws_route_table_association" "g2bkonepPrivate1RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPrivate1Subnet.id
  route_table_id = aws_route_table.g2bkonepPrivate1Routing.id
}

# ============================================================
# 13. Public Subnet B
# ============================================================

resource "aws_subnet" "g2bkonepPublic2Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "g2bkonepPublic2Subnet"
  }
}

# ============================================================
# 14. Public Route Table B
# ============================================================

resource "aws_route_table" "g2bkonepPublic2Routing" {
  depends_on = [
    aws_internet_gateway.g2bkonepIGW
  ]

  vpc_id = aws_vpc.g2bkonepVPC.id

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

# ============================================================
# 15. NAT Gateway B
# ============================================================

resource "aws_eip" "g2bkonepNatGW2EIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "g2bkonepNatGW2" {
  depends_on = [
    aws_internet_gateway.g2bkonepIGW
  ]

  allocation_id = aws_eip.g2bkonepNatGW2EIP.id
  subnet_id     = aws_subnet.g2bkonepPublic2Subnet.id

  tags = {
    Name = "g2bkonepNatGW2"
  }
}

# ============================================================
# 16. Private Subnet B
# ============================================================

resource "aws_subnet" "g2bkonepPrivate2Subnet" {
  vpc_id                  = aws_vpc.g2bkonepVPC.id
  cidr_block              = "172.20.22.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "g2bkonepPrivate2Subnet"
  }
}

# ============================================================
# 17. Private Route Table B
#
# NAT / Peering routes are managed separately.
# ============================================================

resource "aws_route_table" "g2bkonepPrivate2Routing" {
  vpc_id = aws_vpc.g2bkonepVPC.id

  tags = {
    Name = "g2bkonepPrivate2Routing"
  }
}

# ============================================================
# 18. Private B -> NAT Gateway B
# ============================================================

resource "aws_route" "g2b_konep_branch_nat_b" {
  route_table_id = aws_route_table.g2bkonepPrivate2Routing.id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.g2bkonepNatGW2.id
}

# ============================================================
# 19. Private Route Table Association B
# ============================================================

resource "aws_route_table_association" "g2bkonepPrivate2RouteTableAssociation" {
  subnet_id      = aws_subnet.g2bkonepPrivate2Subnet.id
  route_table_id = aws_route_table.g2bkonepPrivate2Routing.id
}

# ============================================================
# 20. Branch EC2 Security Group
# ============================================================

resource "aws_security_group" "g2bkonepSecugroup" {
  name        = "g2bkonepSecugroup"
  description = "Permit http,https,ssh"

  vpc_id = aws_vpc.g2bkonepVPC.id

  tags = {
    Name = "g2bkonepSecugroup"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from Branch VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"]
  }

  # SSH from Bastion Security Group
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    security_groups = [

    ]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# 21. Existing VPC Peering Routes
#
# The following resources are defined in another .tf file.
# Keep them unchanged; do not define them twice.
#
# aws_vpc_peering_connection.g2b_konep_branch_shared
# aws_route.g2b_konep_branch_a_to_shared
# aws_route.g2b_konep_branch_b_to_shared
# aws_route.g2b_konep_shared_to_branch["a"]
# aws_route.g2b_konep_shared_to_branch["b"]
# ============================================================
