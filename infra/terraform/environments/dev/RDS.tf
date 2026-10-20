resource "aws_security_group" "g2b_KonepDBSecugroup" {
  name        = "g2b_KonepDBSecugroup"
  description = "Permit MySQL"
  vpc_id      = aws_vpc.g2b_KonepVPC.id
  tags = {
    Name = "g2b_KonepDBSecugroup"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "g2b_KonepSubnetgroup" {
  name       = "g2b_Konepsubnetgroup"
  subnet_ids = [aws_subnet.g2b_KonepPrivate1Subnet.id, aws_subnet.g2b_KonepPrivate2Subnet.id]

  tags = {
    Name = "g2b_KonepSubnetgroup"
  }
}

resource "aws_rds_cluster" "g2b_KonepDBCluster" {
  depends_on             = [aws_security_group.g2b_KonepDBSecugroup, aws_db_subnet_group.g2b_KonepSubnetgroup]
  cluster_identifier     = "g2b_Konepdb"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  engine_version         = "8.0.mysql_aurora.3.10.3"
  availability_zones     = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name          = "testdb"
  master_username        = "dbadmin"
  master_password        = "toor1234."
  db_subnet_group_name   = aws_db_subnet_group.g2b_KonepSubnetgroup.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.g2b_KonepDBSecugroup.id]

}

resource "aws_rds_cluster_instance" "g2b_KonepDB1" {
  depends_on                 = [aws_rds_cluster.g2b_KonepDBCluster]
  identifier                 = "g2b_Konepdb-1"
  cluster_identifier         = aws_rds_cluster.g2b_KonepDBCluster.id
  instance_class             = "db.t3.medium"
  engine                     = "aurora-mysql"
  engine_version             = "8.0.mysql_aurora.3.10.3"
  availability_zone          = "ap-northeast-2a"
  db_subnet_group_name       = aws_db_subnet_group.g2b_KonepSubnetgroup.name
  auto_minor_version_upgrade = false
}

resource "aws_rds_cluster_instance" "g2b_KonepDB2" {
  depends_on                 = [aws_rds_cluster_instance.g2b_KonepDB1]
  identifier                 = "g2b_Konepdb-2"
  cluster_identifier         = aws_rds_cluster.g2b_KonepDBCluster.id
  instance_class             = "db.t3.medium"
  engine                     = "aurora-mysql"
  engine_version             = "8.0.mysql_aurora.3.10.3"
  availability_zone          = "ap-northeast-2c"
  db_subnet_group_name       = aws_db_subnet_group.g2b_KonepSubnetgroup.name
  auto_minor_version_upgrade = false
}
