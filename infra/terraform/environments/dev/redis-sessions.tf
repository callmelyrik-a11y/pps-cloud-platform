# Shared PHP session store for the existing bWAPP Auto Scaling Group.
# This change provisions Redis only; it does not migrate the MySQL databases.
resource "aws_security_group" "bwapp_session_redis" {
  name_prefix = "g2b-bwapp-redis-"
  description = "Redis access restricted to bWAPP application instances"
  vpc_id      = aws_vpc.g2bkonepVPC.id

  tags = { Name = "g2b-bwapp-redis" }
}

resource "aws_vpc_security_group_ingress_rule" "bwapp_redis_from_app" {
  security_group_id            = aws_security_group.bwapp_session_redis.id
  referenced_security_group_id = aws_security_group.g2bkonepSecugroup.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  description                  = "PHP sessions from existing ASG instances"
}

resource "aws_elasticache_subnet_group" "bwapp_sessions" {
  name = "g2b-bwapp-session-subnets"
  subnet_ids = [
    aws_subnet.g2bkonepPrivate1Subnet.id,
    aws_subnet.g2bkonepPrivate2Subnet.id
  ]
}

resource "aws_elasticache_replication_group" "bwapp_sessions" {
  replication_group_id       = "g2b-bwapp-sessions"
  description                = "Shared session storage for bWAPP PHP ASG"
  engine                     = "redis"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 1
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.bwapp_sessions.name
  security_group_ids         = [aws_security_group.bwapp_session_redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = false
  multi_az_enabled           = false

  tags = { Name = "g2b-bwapp-sessions" }
}

output "bwapp_session_redis_endpoint" {
  description = "TLS-enabled ElastiCache Redis endpoint for PHP session configuration"
  value       = aws_elasticache_replication_group.bwapp_sessions.primary_endpoint_address
}
