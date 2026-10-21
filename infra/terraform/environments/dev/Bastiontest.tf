resource "aws_security_group" "g2bkonepBastionSG" {
  name        = "g2bkonep-bastion-sg"
  description = "SSH access for bastion host"
  vpc_id      = aws_vpc.g2bkonepVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["183.98.32.210/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "g2bkonepBastion" {
  ami           = data.aws_ami.LatestAmi.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.g2b_konep_keypair.key_name
  iam_instance_profile = aws_iam_instance_profile.g2b_konep_ec2_s3_read.name

  subnet_id = aws_subnet.g2bkonepPublic1Subnet.id

  vpc_security_group_ids = [
    aws_security_group.g2bkonepBastionSG.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "g2bkonepBastion"
  }
}
