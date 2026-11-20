
# ============================================================
# G2B KONEP - Application Load Balancer
# 신규 인프라 배포용
# ============================================================

# 1. ALB Target Group
resource "aws_lb_target_group" "g2bkonepALBtargetgroup" {
  name        = "g2bkonepALBtargetgroup"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = aws_vpc.g2bkonepVPC.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "g2bkonepALBtargetgroup"
  }
}

# ============================================================
# 2. Application Load Balancer
# ============================================================

resource "aws_lb" "g2bkonepALB" {
  name               = "g2bkonepALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.g2bkonepSecugroup.id
  ]

  subnets = [
    aws_subnet.g2bkonepPublic1Subnet.id,
    aws_subnet.g2bkonepPublic2Subnet.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "g2bkonepALB"
  }
}


# ============================================================
# 4. ALB DNS Output
# ============================================================

output "g2bkonep_alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.g2bkonepALB.dns_name
}
