
# ============================================================
# G2B KONEP - Import Existing NAT Routes
# ============================================================

# EKS App A
import {
  to = aws_route.g2b_konep_app_nat["a"]
  id = "rtb-00f7c6c2aa7e11760_0.0.0.0/0"
}

# EKS App B
import {
  to = aws_route.g2b_konep_app_nat["b"]
  id = "rtb-04af2c0c401a456bd_0.0.0.0/0"
}

# Branch Private A
import {
  to = aws_route.g2b_konep_branch_nat_a
  id = "rtb-04f060203d8c9de92_0.0.0.0/0"
}

# Branch Private B
import {
  to = aws_route.g2b_konep_branch_nat_b
  id = "rtb-07c7162a17ea05f15_0.0.0.0/0"
}
