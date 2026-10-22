
# ============================================================
# G2B KONEP - Branch <-> Shared EKS VPC Peering
# Same AWS Account / ap-northeast-2
# ============================================================

# 1. VPC Peering
resource "aws_vpc_peering_connection" "g2b_konep_branch_shared" {
  vpc_id      = aws_vpc.g2bkonepVPC.id
  peer_vpc_id = aws_vpc.g2b_konep.id

  auto_accept = true

  tags = merge(local.g2b_konep_common_tags, {
    Name = "g2b-konep-${var.environment}-branch-shared-pcx"
  })
}

# 2. Branch Private Subnet A -> Shared EKS
resource "aws_route" "g2b_konep_branch_a_to_shared" {
  route_table_id = aws_route_table.g2bkonepPrivate1Routing.id

  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.g2b_konep_branch_shared.id
}

# 3. Branch Private Subnet B -> Shared EKS
resource "aws_route" "g2b_konep_branch_b_to_shared" {
  route_table_id = aws_route_table.g2bkonepPrivate2Routing.id

  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.g2b_konep_branch_shared.id
}

# 4. Shared EKS App Subnets -> Branch
resource "aws_route" "g2b_konep_shared_to_branch" {
  for_each = aws_route_table.app

  route_table_id = each.value.id

  destination_cidr_block    = aws_vpc.g2bkonepVPC.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.g2b_konep_branch_shared.id
}

# 5. Peering Output
output "g2b_konep_branch_shared_peering_id" {
  description = "Branch to Shared EKS VPC Peering ID"
  value       = aws_vpc_peering_connection.g2b_konep_branch_shared.id
}
