#!/bin/bash
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
echo var.g2b_konep_db_master_password | passwd --stdin root 
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd

yum install -y httpd awscli

aws s3 cp s3://g2b-konep-513329232596-ap-northeast-2-an/ /var/www/html/ --recursive

systemctl enable --now httpd.service