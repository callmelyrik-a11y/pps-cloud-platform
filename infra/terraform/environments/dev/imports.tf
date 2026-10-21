import {
  to = aws_lb_listener.g2bkonepALBhttpslistener
  id = "arn:aws:elasticloadbalancing:ap-northeast-2:513329232596:listener/app/g2bkonepALB/13d0d90cf2d25377/805aa1d595845e6c"
}

import {
  to = aws_eks_access_entry.g2b_konep_megastudy
  id = "g2b-konep-dev-eks:arn:aws:iam::513329232596:user/megastudy"
}

import {
  to = aws_eks_access_policy_association.g2b_konep_megastudy_admin
  id = "g2b-konep-dev-eks#arn:aws:iam::513329232596:user/megastudy#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}
