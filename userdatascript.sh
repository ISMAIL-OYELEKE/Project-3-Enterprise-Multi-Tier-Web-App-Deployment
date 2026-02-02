#!/bin/bash
dnf update -y
dnf install -y httpd wget php php-mysqli php-json php-common php-devel
systemctl start httpd
systemctl enable httpd
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
echo "Healthy" > /var/www/html/health.html
