output "vpc_id" {
  value = aws_vpc.main.id
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

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_worker_asg_name" {
  value = aws_eks_node_group.general.resources[0].autoscaling_groups[0].name
}

output "aurora_writer_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_master_secret_arn" {
  value = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "s3_frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}

output "cloudwatch_dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}
