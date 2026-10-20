
resource "aws_launch_template" "g2b_KonepLaunchTemplate" {
  depends_on             = [aws_security_group.g2b_KonepSecugroup]
  name_prefix            = "g2b_KonepAutoScalingGroup"
  image_id               = data.aws_ami.LatestAmi.id
  key_name               = aws_key_pair.tf_keypair.key_name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.g2b_KonepSecugroup.id]


  user_data = filebase64("${path.module}/script.sh")

  iam_instance_profile {
    name = "g2b_KonepEC2S3ReadRole"
  }

}

resource "aws_autoscaling_group" "g2b_KonepAutoScalingGroup" {
  depends_on          = [aws_launch_template.g2b_KonepLaunchTemplate, aws_nat_gateway.g2b_KonepNatGW1, aws_nat_gateway.g2b_KonepNatGW2]
  desired_capacity    = 4
  max_size            = 10
  min_size            = 4
  vpc_zone_identifier = [aws_subnet.g2b_KonepPrivate1Subnet.id, aws_subnet.g2b_KonepPrivate2Subnet.id]



  launch_template {
    id      = aws_launch_template.g2b_KonepLaunchTemplate.id
    version = aws_launch_template.g2b_KonepLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "g2b_KonepAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

}

resource "aws_autoscaling_attachment" "g2b_KonepAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.g2b_KonepAutoScalingGroup.id
  lb_target_group_arn    = aws_lb_target_group.g2b_KonepALBtargetgroup.arn
}
