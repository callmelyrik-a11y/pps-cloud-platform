output "vpc_id" {
  value = aws_vpc.g2b_konep.id
}

output "public_subnet_ids" {
  value = [aws_subnet.tier["public_a"].id, aws_subnet.tier["public_b"].id]
}

output "private_app_subnet_ids" {
  value = [aws_subnet.tier["app_a"].id, aws_subnet.tier["app_b"].id]
}

output "private_db_subnet_ids" {
  value = [aws_subnet.tier["db_a"].id, aws_subnet.tier["db_b"].id]
}

output "nat_eips" {
  value = { for az, ip in aws_eip.nat : az => ip.public_ip }
}

#output "g2b_konep_cluster_autoscaler_role_arn" {
#  description = "IAM Role ARN for G2B KONEP Cluster Autoscaler"
#  value       = aws_iam_role.g2b_konep_cluster_autoscaler_role.arn
#}

output "g2b_konep_cluster_autoscaler_release" {
  description = "Helm release name for Cluster Autoscaler"
  value       = helm_release.g2b_konep_cluster_autoscaler.name
}

output "eks_cluster_name" {
  value = aws_eks_cluster.g2b_konep_eks.name
}

#output "eks_worker_asg_name" {
#  value = aws_eks_node_group.general.resources[0].autoscaling_groups[0].name
#}

#output "aurora_writer_endpoint" {
#  value = aws_rds_cluster.aurora.endpoint
#}

#output "aurora_reader_endpoint" {
#  value = aws_rds_cluster.aurora.reader_endpoint
#}

#output "aurora_master_secret_arn" {
#  value = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
#}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "s3_frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}

# ============================================================
# 5. Outputs for Kubernetes Deployment Pipeline
# ============================================================

output "g2b_konep_autoscaler_cluster_name" {
  value = aws_eks_cluster.g2b_konep_eks.name
}

output "g2b_konep_autoscaler_namespace" {
  value = local.g2b_konep_cluster_autoscaler_namespace
}

output "g2b_konep_autoscaler_service_account" {
  value = local.g2b_konep_cluster_autoscaler_sa
}

output "g2b_konep_autoscaler_role_arn" {
  value = aws_iam_role.g2b_konep_cluster_autoscaler_role.arn
}

#output "cloudwatch_dashboard_name" {
#  value = aws_cloudwatch_dashboard.main.dashboard_name
#}
