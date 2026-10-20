resource "aws_security_group" "g2bkonepDBSecugroup" {
  name        = "g2bkonepDBSecugroup"
  description = "Permit MySQL"
  vpc_id      = aws_vpc.g2bkonepVPC.id
  tags = {
    Name = "g2bkonepDBSecugroup"
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

resource "aws_db_subnet_group" "g2bkonepSubnetgroup" {
  name       = "g2bkonepsubnetgroup"
  subnet_ids = [aws_subnet.g2bkonepPrivate1Subnet.id, aws_subnet.g2bkonepPrivate2Subnet.id]

  tags = {
    Name = "g2bkonepSubnetgroup"
  }
}

resource "aws_rds_cluster" "g2bkonepDBCluster" {
  depends_on             = [aws_security_group.g2bkonepDBSecugroup, aws_db_subnet_group.g2bkonepSubnetgroup]
  cluster_identifier     = "g2bkonepdb"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  engine_version         = "8.0.mysql_aurora.3.10.3"
  availability_zones     = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name          = "testdb"
  master_username        = "dbadmin"
  master_password        = "toor1234."
  db_subnet_group_name   = aws_db_subnet_group.g2bkonepSubnetgroup.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.g2bkonepDBSecugroup.id]

}

resource "aws_rds_cluster_instance" "g2bkonepDB1" {
  depends_on                 = [aws_rds_cluster.g2bkonepDBCluster]
  identifier                 = "g2bkonepdb-1"
  cluster_identifier         = aws_rds_cluster.g2bkonepDBCluster.id
  instance_class             = "db.t3.medium"
  engine                     = "aurora-mysql"
  engine_version             = "8.0.mysql_aurora.3.10.3"
  availability_zone          = "ap-northeast-2a"
  db_subnet_group_name       = aws_db_subnet_group.g2bkonepSubnetgroup.name
  auto_minor_version_upgrade = false
}

resource "aws_rds_cluster_instance" "g2bkonepDB2" {
  depends_on                 = [aws_rds_cluster_instance.g2bkonepDB1]
  identifier                 = "g2bkonepdb-2"
  cluster_identifier         = aws_rds_cluster.g2bkonepDBCluster.id
  instance_class             = "db.t3.medium"
  engine                     = "aurora-mysql"
  engine_version             = "8.0.mysql_aurora.3.10.3"
  availability_zone          = "ap-northeast-2c"
  db_subnet_group_name       = aws_db_subnet_group.g2bkonepSubnetgroup.name
  auto_minor_version_upgrade = false
}
