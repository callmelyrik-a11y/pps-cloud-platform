
# ============================================================
# G2B KONEP - Cluster Autoscaler AWS Infrastructure
# ============================================================

locals {
  g2b_konep_cluster_autoscaler_namespace = "kube-system"
  g2b_konep_cluster_autoscaler_sa        = "g2b-konep-cluster-autoscaler"
}

# ============================================================
# 1. ASG Auto Discovery Tags
# ============================================================

resource "aws_autoscaling_group_tag" "g2b_konep_ca_enabled" {
  autoscaling_group_name = aws_eks_node_group.g2b_konep_general_node_group.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "g2b_konep_ca_cluster" {
  autoscaling_group_name = aws_eks_node_group.g2b_konep_general_node_group.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}

# ============================================================
# 2. IAM Role - EKS Pod Identity
# ============================================================

data "aws_iam_policy_document" "g2b_konep_ca_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "g2b_konep_cluster_autoscaler_role" {
  name = "${local.name}-cluster-autoscaler-role"

  assume_role_policy = data.aws_iam_policy_document.g2b_konep_ca_assume_role.json

  tags = local.g2b_konep_common_tags
}

# ============================================================
# 3. Cluster Autoscaler IAM Policy
# ============================================================

data "aws_iam_policy_document" "g2b_konep_cluster_autoscaler_policy" {
  statement {
    sid    = "ClusterAutoscalerRead"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ClusterAutoscalerWrite"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "g2b_konep_cluster_autoscaler_policy" {
  name   = "${local.name}-cluster-autoscaler-policy"
  policy = data.aws_iam_policy_document.g2b_konep_cluster_autoscaler_policy.json

  tags = local.g2b_konep_common_tags
}

resource "aws_iam_role_policy_attachment" "g2b_konep_cluster_autoscaler_attach" {
  role       = aws_iam_role.g2b_konep_cluster_autoscaler_role.name
  policy_arn = aws_iam_policy.g2b_konep_cluster_autoscaler_policy.arn
}

# ============================================================
# 4. EKS Pod Identity Association
# ============================================================

resource "aws_eks_pod_identity_association" "g2b_konep_cluster_autoscaler" {
  cluster_name = aws_eks_cluster.g2b_konep_eks.name

  namespace       = local.g2b_konep_cluster_autoscaler_namespace
  service_account = local.g2b_konep_cluster_autoscaler_sa
  role_arn        = aws_iam_role.g2b_konep_cluster_autoscaler_role.arn

  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.g2b_konep_eks
    ]
  }

  depends_on = [
    aws_eks_addon.g2b_konep_pod_identity_agent,
    aws_iam_role_policy_attachment.g2b_konep_cluster_autoscaler_attach
  ]

  tags = local.g2b_konep_common_tags
}


