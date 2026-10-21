
# ============================================================
# G2B KONEP - EKS Cluster
# ============================================================

# ============================================================
# 1. EKS Control Plane IAM Role
# ============================================================

resource "aws_iam_role" "g2b_konep_eks_cluster_role" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.g2b_konep_common_tags
}

resource "aws_iam_role_policy_attachment" "g2b_konep_eks_cluster_policy" {
  role       = aws_iam_role.g2b_konep_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ============================================================
# 2. EKS Control Plane CloudWatch Logs
# ============================================================

resource "aws_cloudwatch_log_group" "g2b_konep_eks_control_plane" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7

  tags = merge(local.g2b_konep_common_tags, {
    Name = "${var.project}-${var.environment}-control-plane-logs"
  })
}

# ============================================================
# 3. EKS Cluster
# ============================================================

resource "aws_eks_cluster" "g2b_konep_eks" {
  name     = "g2b-konep-dev-eks"
  role_arn = aws_iam_role.g2b_konep_eks_cluster_role.arn
  version  = var.cluster_version

  tags = local.g2b_konep_common_tags

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.tier["app_a"].id,
      aws_subnet.tier["app_b"].id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true

    public_access_cidrs = var.cluster_public_access_cidrs
  }

  enabled_cluster_log_types = [
    "api",
    "audit"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.g2b_konep_eks_cluster_policy,
    aws_cloudwatch_log_group.g2b_konep_eks_control_plane,
    aws_route_table_association.app
  ]

  tags = merge(local.g2b_konep_common_tags, {
    Name = local.cluster_name
  })
}

# ============================================================
# 4. EKS Worker Node IAM Role
# ============================================================

resource "aws_iam_role" "g2b_konep_eks_nodes_role" {
  name = "${local.g2b_konep_common_tags.Project}-${var.environment}-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.g2b_konep_common_tags
}

resource "aws_iam_role_policy_attachment" "g2b_konep_node_worker_policy" {
  role       = aws_iam_role.g2b_konep_eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "g2b_konep_node_ecr_policy" {
  role       = aws_iam_role.g2b_konep_eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 학습 환경에서는 Node Role에 CNI 권한을 부여.
resource "aws_iam_role_policy_attachment" "g2b_konep_node_cni_policy" {
  role       = aws_iam_role.g2b_konep_eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ============================================================
# 5. EKS Managed Node Group + Auto Scaling
# ============================================================

resource "aws_eks_node_group" "g2b_konep_general_node_group" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name

  node_group_name = "${local.g2b_konep_common_tags.Project}-general-ng"

  node_role_arn = aws_iam_role.g2b_konep_eks_nodes_role.arn

  subnet_ids = [
    aws_subnet.tier["app_a"].id,
    aws_subnet.tier["app_b"].id
  ]

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 30

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    workload = "general"
  }

  # Cluster Autoscaler가 변경한 desired_size를 유지
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.g2b_konep_node_worker_policy,
    aws_iam_role_policy_attachment.g2b_konep_node_ecr_policy,
    aws_iam_role_policy_attachment.g2b_konep_node_cni_policy,
    aws_route_table_association.app
  ]

  tags = merge(local.g2b_konep_common_tags, {
    Name = "${local.g2b_konep_common_}-general-ng"
  })
}

# ============================================================
# 6. EKS Managed Add-ons
# ============================================================

resource "aws_eks_addon" "g2b_konep_coredns" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.g2b_konep_general_node_group
  ]

  tags = local.g2b_konep_common_tags
}

resource "aws_eks_addon" "g2b_konep_kube_proxy" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.g2b_konep_general_node_group
  ]

  tags = local.g2b_konep_common_tags
}

resource "aws_eks_addon" "g2b_konep_vpc_cni" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.g2b_konep_general_node_group
  ]

  tags = local.g2b_konep_common_tags
}

resource "aws_eks_addon" "g2b_konep_pod_identity_agent" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_node_group.g2b_konep_general_node_group
  ]

  tags = local.g2b_konep_common_tags
}

# ============================================================
# 7. EKS Administrator Access Entry
# ============================================================

resource "aws_eks_access_entry" "g2b_konep_admin" {
  count = var.eks_admin_principal_arn == null ? 0 : 1

  cluster_name  = aws_eks_cluster.g2b_konep_eks.name
  principal_arn = var.eks_admin_principal_arn
  type          = "STANDARD"

  tags = local.g2b_konep_common_tags
}

resource "aws_eks_access_policy_association" "g2b_konep_admin" {
  count = var.eks_admin_principal_arn == null ? 0 : 1

  cluster_name = aws_eks_cluster.g2b_konep_eks.name

  principal_arn = aws_eks_access_entry.g2b_konep_admin[0].principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
