# 기존 IAM 사용자의 EKS 액세스 항목
resource "aws_eks_access_entry" "g2b_konep_megastudy" {
  cluster_name  = aws_eks_cluster.g2b_konep_eks.name
  principal_arn = "arn:aws:iam::513329232596:user/megastudy"
  type          = "STANDARD"

  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.g2b_konep_eks
    ]
  }
}

# 클러스터 전체 관리자 권한 연결
resource "aws_eks_access_policy_association" "g2b_konep_megastudy_admin" {
  cluster_name  = aws_eks_access_entry.g2b_konep_megastudy.cluster_name
  principal_arn = aws_eks_access_entry.g2b_konep_megastudy.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.g2b_konep_eks
    ]
  }
}
