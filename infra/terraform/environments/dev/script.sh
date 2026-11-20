#!/bin/bash

hostnamectl --static set-hostname MyWeb

# GitHub Secret → GitHub Actions → Terraform → User Data
# root 계정의 비밀번호 해시 설정
usermod --password '${ec2_root_password_hash}' root

# Serial Console용 비밀번호만 설정
# SSH 비밀번호 인증과 root SSH 로그인은 활성화하지 않음

# Apache, MariaDB, PHP 설치
yum install -y httpd mariadb-server mariadb
yum install -y php php-mysqlnd php-gd
yum install -y wget unzip

systemctl enable --now mariadb httpd

# 기존 bWAPP 실습용 MariaDB 설정
echo -e "\n\ntoor1234.\ntoor1234.\ny\nn\ny\ny\n" \
  | /usr/bin/mysql_secure_installation

mysql -uroot -ptoor1234. -e \
  "CREATE USER 'bwapp'@'localhost' IDENTIFIED BY 'bug';
   GRANT ALL PRIVILEGES ON bWAPP.* TO 'bwapp'@'localhost';
   FLUSH PRIVILEGES;"

# bWAPP 다운로드 및 배치
wget https://github.com/ncs10322/aws/raw/main/bWAPP.zip
unzip bWAPP.zip
mv bWAPP/* /var/www/html/

chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

chmod 777 /var/www/html/passwords \
  /var/www/html/images \
  /var/www/html/documents

sed -i 's/\$db_username = "root"/\$db_username = "bwapp"/g' \
  /var/www/html/admin/settings.php

systemctl restart httpd
