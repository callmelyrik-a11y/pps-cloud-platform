resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-igw" }
}

resource "aws_subnet" "tier" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.tier == "public"

  tags = merge(
    { Name = "${local.name}-${each.key}" },
    each.value.tier == "public" ? { "kubernetes.io/role/elb" = "1" } : {},
    each.value.tier == "app" ? { "kubernetes.io/role/internal-elb" = "1" } : {}
  )
}

resource "aws_eip" "nat" {
  for_each = toset(["a", "b"])
  domain   = "vpc"
  tags     = { Name = "${local.name}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(["a", "b"])
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.tier["public_${each.key}"].id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${local.name}-nat-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = toset(["a", "b"])
  subnet_id      = aws_subnet.tier["public_${each.key}"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  for_each = toset(["a", "b"])
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = { Name = "${local.name}-app-${each.key}-rt" }
}

resource "aws_route_table_association" "app" {
  for_each       = toset(["a", "b"])
  subnet_id      = aws_subnet.tier["app_${each.key}"].id
  route_table_id = aws_route_table.app[each.key].id
}

# DB subnets have only the automatic VPC-local route, no NAT / IGW default route.
resource "aws_route_table" "db" {
  for_each = toset(["a", "b"])
  vpc_id   = aws_vpc.main.id
  tags     = { Name = "${local.name}-db-${each.key}-rt" }
}

resource "aws_route_table_association" "db" {
  for_each       = toset(["a", "b"])
  subnet_id      = aws_subnet.tier["db_${each.key}"].id
  route_table_id = aws_route_table.db[each.key].id
}
