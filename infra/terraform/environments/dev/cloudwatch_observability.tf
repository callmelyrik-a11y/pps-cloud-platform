
# ============================================================
# G2B KONEP - CloudWatch Observability
# ============================================================

# 1. CloudWatch Agent IAM Role
resource "aws_iam_role" "g2b_konep_cloudwatch_role" {
  name = "g2b-konep-dev-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = local.g2b_konep_common_tags
}

# 2. CloudWatch Agent IAM Policy
resource "aws_iam_role_policy_attachment" "g2b_konep_cloudwatch_policy" {
  role = aws_iam_role.g2b_konep_cloudwatch_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 3. EKS CloudWatch Observability Add-on
resource "aws_eks_addon" "g2b_konep_cloudwatch" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name
  addon_name   = "amazon-cloudwatch-observability"

  pod_identity_association {
    service_account = "cloudwatch-agent"
    role_arn        = aws_iam_role.g2b_konep_cloudwatch_role.arn
  }

  depends_on = [
    aws_eks_addon.g2b_konep_pod_identity_agent,
    aws_iam_role_policy_attachment.g2b_konep_cloudwatch_policy
  ]

  tags = local.g2b_konep_common_tags
}
