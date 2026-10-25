
# ============================================================
# G2B KONEP - VPC / Subnet / Routing
# ============================================================

# ============================================================
# 1. VPC
# ============================================================

resource "aws_vpc" "g2b_konep" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

# ============================================================
# 2. Internet Gateway
# ============================================================

resource "aws_internet_gateway" "g2b_konep" {
  vpc_id = aws_vpc.g2b_konep.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# ============================================================
# 3. Subnets
# Public / App / DB x 2 AZ
# ============================================================

resource "aws_subnet" "tier" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.g2b_konep.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.tier == "public"

  tags = merge(
    {
      Name = "${local.name}-${each.key}"
    },
    each.value.tier == "public" ? {
      "kubernetes.io/role/elb" = "1"
    } : {},
    each.value.tier == "app" ? {
      "kubernetes.io/role/internal-elb" = "1"
    } : {}
  )
}

# ============================================================
# 4. NAT Gateway Elastic IP
# ============================================================

resource "aws_eip" "nat" {
  for_each = toset(["a", "b"])

  tags = {
    Name = "${local.name}-nat-eip-${each.key}"
  }
}

# ============================================================
# 5. NAT Gateway
# One NAT Gateway per AZ
# ============================================================

resource "aws_nat_gateway" "nat" {
  for_each = toset(["a", "b"])

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.tier["public_${each.key}"].id

  depends_on = [
    aws_internet_gateway.g2b_konep
  ]

  tags = {
    Name = "${local.name}-nat-${each.key}"
  }
}

# ============================================================
# 6. Public Route Table
# Public Subnet -> Internet Gateway
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.g2b_konep.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.g2b_konep.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# ============================================================
# 7. Public Route Table Association
# ============================================================

resource "aws_route_table_association" "public" {
  for_each = toset(["a", "b"])

  subnet_id      = aws_subnet.tier["public_${each.key}"].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# 8. App Private Route Tables
#
# IMPORTANT:
# Do not define inline route blocks here.
# NAT and VPC Peering routes are managed by aws_route.
# ============================================================

resource "aws_route_table" "app" {
  for_each = toset(["a", "b"])

  vpc_id = aws_vpc.g2b_konep.id

  tags = {
    Name = "${local.name}-app-${each.key}-rt"
  }
}

# ============================================================
# 9. App Private Route -> NAT Gateway
#
# App A -> NAT A
# App B -> NAT B
# ============================================================

resource "aws_route" "g2b_konep_app_nat" {
  for_each = toset(["a", "b"])

  route_table_id = aws_route_table.app[each.key].id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat[each.key].id
}

# ============================================================
# 10. App Route Table Association
# ============================================================

resource "aws_route_table_association" "app" {
  for_each = toset(["a", "b"])

  subnet_id      = aws_subnet.tier["app_${each.key}"].id
  route_table_id = aws_route_table.app[each.key].id
}

# ============================================================
# 11. DB Private Route Tables
#
# DB subnets use VPC-local routing only.
# No NAT Gateway / Internet Gateway default route.
# ============================================================

resource "aws_route_table" "db" {
  for_each = toset(["a", "b"])

  vpc_id = aws_vpc.g2b_konep.id

  tags = {
    Name = "${local.name}-db-${each.key}-rt"
  }
}

# ============================================================
# 12. DB Route Table Association
# ============================================================

resource "aws_route_table_association" "db" {
  for_each = toset(["a", "b"])

  subnet_id      = aws_subnet.tier["db_${each.key}"].id
  route_table_id = aws_route_table.db[each.key].id
}

# ============================================================
# VPC Peering Routes
#
# Existing aws_route resources in the Peering Terraform file
# must remain unchanged.
#
# Expected existing resources:
#
# aws_vpc_peering_connection.g2b_konep_branch_shared
# aws_route.g2b_konep_shared_to_branch["a"]
# aws_route.g2b_konep_shared_to_branch["b"]
# aws_route.g2b_konep_branch_a_to_shared
# aws_route.g2b_konep_branch_b_to_shared
#
# Do not duplicate these resources here.
# ============================================================
