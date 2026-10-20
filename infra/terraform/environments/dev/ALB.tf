resource "aws_lb_target_group" "g2b_KonepALBtargetgroup" {
  name     = "g2b_KonepALBtargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.g2b_KonepVPC.id
}

resource "aws_lb" "g2b_KonepALB" {
  depends_on         = [aws_lb_target_group.g2b_KonepALBtargetgroup]
  name               = "g2b_KonepALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.g2b_KonepSecugroup.id]
  subnets            = [aws_subnet.g2b_KonepPublic1Subnet.id, aws_subnet.g2b_KonepPublic2Subnet.id]

  tags = {
    Name = "g2b_KonepALB"
  }
}

resource "aws_lb_listener" "g2b_KonepALBhttplistener" {
  depends_on        = [aws_lb_target_group.g2b_KonepALBtargetgroup]
  load_balancer_arn = aws_lb.g2b_KonepALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.g2b_KonepALBtargetgroup.arn
  }
}

resource "aws_lb_listener" "g2b_KonepALBhttpslistener" {
  load_balancer_arn = aws_lb.g2b_KonepALB.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = "arn:aws:acm:ap-northeast-2:513329232596:certificate/e94ac631-4acd-4be4-a88b-ca347b1a07ce"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.g2b_KonepALBtargetgroup.arn
  }
}
