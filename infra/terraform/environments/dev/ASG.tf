# 기존 IAM Role 조회
data "aws_iam_role" "g2b_konep_ec2_s3_read" {
  name = "g2bkonepEC2S3ReadRole"
}

# 기존 Role을 담는 Instance Profile 생성
resource "aws_iam_instance_profile" "g2b_konep_ec2_s3_read" {
  name = "g2b-konep-dev-ec2-s3-read-profile"
  role = data.aws_iam_role.g2b_konep_ec2_s3_read.name
}

resource "aws_launch_template" "g2bkonepLaunchTemplate" {
  name_prefix            = "g2bkonepAutoScalingGroup"
  image_id               = data.aws_ami.LatestAmi.id
  key_name               = aws_key_pair.g2b_konep_keypair.key_name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.g2bkonepSecugroup.id]

  user_data = filebase64("${path.module}/script.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.g2b_konep_ec2_s3_read.name
  }
}

resource "aws_autoscaling_group" "g2bkonepAutoScalingGroup" {
  depends_on          = [aws_launch_template.g2bkonepLaunchTemplate, aws_nat_gateway.g2bkonepNatGW1, aws_nat_gateway.g2bkonepNatGW2]
  desired_capacity    = 4
  max_size            = 10
  min_size            = 4
  vpc_zone_identifier = [aws_subnet.g2bkonepPrivate1Subnet.id, aws_subnet.g2bkonepPrivate2Subnet.id]



  launch_template {
    id      = aws_launch_template.g2bkonepLaunchTemplate.id
    version = aws_launch_template.g2bkonepLaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "g2bkonepAutoScalingGroup"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

}

resource "aws_autoscaling_attachment" "g2bkonepAutoScalingALBattachment" {
  autoscaling_group_name = aws_autoscaling_group.g2bkonepAutoScalingGroup.id
  lb_target_group_arn    = aws_lb_target_group.g2bkonepALBtargetgroup.arn
}
