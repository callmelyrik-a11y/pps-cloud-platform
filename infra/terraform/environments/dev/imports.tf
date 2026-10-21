# ============================================================
# G2B KONEP - Existing Resource Imports
# ============================================================

# Existing ALB HTTPS listener
import {
  to = aws_lb_listener.g2bkonepALBhttpslistener
  id = "arn:aws:elasticloadbalancing:ap-northeast-2:513329232596:listener/app/g2bkonepALB/13d0d90cf2d25377/805aa1d595845e6c"
}

# EKS Access Entry:
# Remove import blocks for objects that do not exist.
# The resources remain managed in eks_access.tf.