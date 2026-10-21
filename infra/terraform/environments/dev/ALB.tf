resource "aws_lb_target_group" "g2bkonepALBtargetgroup" {
  name     = "g2bkonepALBtargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.g2bkonepVPC.id
}

resource "aws_lb" "g2bkonepALB" {
  depends_on         = [aws_lb_target_group.g2bkonepALBtargetgroup]
  name               = "g2bkonepALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.g2bkonepSecugroup.id]
  subnets            = [aws_subnet.g2bkonepPublic1Subnet.id, aws_subnet.g2bkonepPublic2Subnet.id]

  tags = {
    Name = "g2bkonepALB"
  }
}

resource "aws_lb_listener" "g2bkonepALBhttplistener" {
  depends_on        = [aws_lb_target_group.g2bkonepALBtargetgroup]
  load_balancer_arn = aws_lb.g2bkonepALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.g2bkonepALBtargetgroup.arn
  }
}

# ============================================================
# G2B KONEP - Existing ACM Wildcard Certificate
# ============================================================

data "aws_acm_certificate" "g2b_konep_origin" {
  domain      = "*.konep7777.shop"
  statuses    = ["ISSUED"]
  most_recent = true
}

# ============================================================
# ALB HTTPS Listener - Port 443
# ============================================================

resource "aws_lb_listener" "g2bkonepALBhttpslistener" {
  load_balancer_arn = aws_lb.g2bkonepALB.arn

  port     = 443
  protocol = "HTTPS"

  certificate_arn = "arn:aws:acm:ap-northeast-2:513329232596:certificate/1b670da1-5055-45f1-a80d-534002473bda"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"

    target_group_arn = aws_lb_target_group.g2bkonepALBtargetgroup.arn
  }
}

