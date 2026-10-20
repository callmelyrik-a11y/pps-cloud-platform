resource "aws_security_group" "g2b_KonepBastionSG" {
  name        = "g2b_Konep-bastion-sg"
  description = "SSH access for bastion host"
  vpc_id      = aws_vpc.g2b_KonepVPC.id

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

resource "aws_instance" "g2b_KonepBastion" {
  ami           = data.aws_ami.LatestAmi.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.tf_keypair.key_name

  subnet_id = aws_subnet.g2b_KonepPublic1Subnet.id

  vpc_security_group_ids = [
    aws_security_group.g2b_KonepBastionSG.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "g2b_KonepBastion"
  }
}
