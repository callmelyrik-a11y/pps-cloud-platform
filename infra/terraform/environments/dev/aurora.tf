resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora-sg"
  description = "Aurora MySQL access only from EKS managed node security group"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${local.name}-aurora-sg" }
}

# Managed nodes receive the cluster security group by default.
# This uses that group as the source instead of exposing 3306 publicly.
resource "aws_vpc_security_group_ingress_rule" "aurora_from_eks" {
  security_group_id            = aws_security_group.aurora.id
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "MySQL from EKS nodes"
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name}-aurora-subnets"
  subnet_ids = [aws_subnet.tier["db_a"].id, aws_subnet.tier["db_b"].id]
  tags       = { Name = "${local.name}-aurora-subnets" }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.name}-aurora"
  engine             = "aurora-mysql"
  engine_mode        = "provisioned" # Required for Aurora Serverless v2.
  engine_version     = var.aurora_engine_version

  database_name               = "pps"
  master_username             = "ppsadmin"
  manage_master_user_password = true # AWS Secrets Manager manages password.

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]
  storage_encrypted      = true

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true # Dev ONLY. Data may be lost on destroy.
  apply_immediately       = true

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_acu
    max_capacity = var.aurora_max_acu
  }

  tags = { Name = "${local.name}-aurora" }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier          = "${local.name}-writer"
  cluster_identifier  = aws_rds_cluster.aurora.id
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  instance_class      = "db.serverless"
  availability_zone   = var.availability_zones[0]
  publicly_accessible = false
  apply_immediately   = true
  tags                = { Name = "${local.name}-writer" }
}

resource "aws_rds_cluster_instance" "reader" {
  identifier          = "${local.name}-reader"
  cluster_identifier  = aws_rds_cluster.aurora.id
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  instance_class      = "db.serverless"
  availability_zone   = var.availability_zones[1]
  publicly_accessible = false
  apply_immediately   = true

  depends_on = [aws_rds_cluster_instance.writer]
  tags       = { Name = "${local.name}-reader" }
}
