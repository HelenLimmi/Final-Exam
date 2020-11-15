#!/bin/bash

###########################################################################
### Script for installing and configuring Zabbix server 5.0 on Centos 8 ###
###########################################################################

#---Configuration file
. ZabbixConfig
. passwd

#---Set timezone
echo "###Setting timezone and synchronize the system clock."
timedatectl set-timezone $TIMEZONE
#install and enable 'Chrony' to synchronize the system clock
rpm -qa | grep chrony || dnf install -y chrony
systemctl enable chronyd --now

#---Configuring the firewall: 
	#80 - port for http requests (web interface); 
	#443 - for https requests (web interface); 
	#10050,10051 - ports for receiving information from zabbix agents.
echo "###Configuring the firewall."
firewall-cmd --permanent --add-port={80/tcp,443/tcp,10051/tcp,10050/tcp,10050/udp,10051/udp}
firewall-cmd --reload

#---Configuring SELinux
echo "###Temporarily disable SELinux and set it to permissive mode."
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

#---Install mariadb server
echo "###Install mariadb server."
rpm -qa | grep mariadb-server || dnf install -y mariadb-server
systemctl enable mariadb --now
#setting a password for the root
mysql -u root -e "SET PASSWORD FOR root@'localhost' = PASSWORD('$MYSQL')"

#---Install Nginx
echo "###Install Nginx."
rpm -qa | grep nginx || dnf install -y nginx
systemctl enable nginx --now

#---Install PHP
echo "###Install PHP."
rpm -qa | grep -E "(php|php-fpm|php-mysqli)" || dnf install -y php php-fpm php-mysqli
#configure /etc/php.ini
echo "###Configuring parameters of /etc/php.ini file."
sed -i "s+;date.timezone =.*+date.timezone = '$TIMEZONE'+" /etc/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = $EXECUTION_TIME/" /etc/php.ini
sed -i "s/post_max_size =.*/post_max_size = $POST_MAX_SIZE/" /etc/php.ini
sed -i "s/max_input_time =.*/max_input_time = $MAX_INPUT_TIME/" /etc/php.ini
#run php-fpm
systemctl enable php-fpm --now

#---Configuring file /etc/nginx/nginx.conf (for NGINX to process PHP)
echo "###Configuring file /etc/nginx/nginx.conf (for NGINX to process PHP)"
filePHP="/etc/nginx/nginx.conf"
stringPHP1='location ~ \\.php$ {'
stringPHP2='set $root_path /usr/share/nginx/html;'
stringPHP3='fastcgi_pass unix:/run/php-fpm/www.sock;'
stringPHP4='fastcgi_index index.php;'
stringPHP5='fastcgi_param SCRIPT_FILENAME $root_path$fastcgi_script_name;'
stringPHP6='include fastcgi_params;'
stringPHP7='fastcgi_param DOCUMENT_ROOT $root_path; }'
stringPHP="$stringPHP1\n$stringPHP2\n$stringPHP3\n$stringPHP4\n$stringPHP5\n$stringPHP6\n$stringPHP7"

#check if PHP config exists in file /etc/nginx/nginx.conf
if grep -w "$stringPHP1" $filePHP && \
	grep -w "$stringPHP3" $filePHP && \
	grep -w "$stringPHP4" $filePHP && \
	grep -w "$stringPHP5" $filePHP && \
	grep -w "$stringPHP6" $filePHP && \
	grep -w "$stringPHP7" $filePHP; then 
    echo "PHP config has already existed."
else
    echo "PHP config is not exist. Creating new one."
	sed -i "50i\\$stringPHP" $filePHP
fi

#---Checking nginx settings and restart nginx service
echo "###Checking nginx settings."
nginx -t
sleep 3
echo "###Restart nginx service."
systemctl restart nginx
#creating index.php in NGINX home directory
echo "<?php phpinfo(); ?>" >> /usr/share/nginx/html/index.php

#---Install Zabbix
echo "###Installing Zabbix Server 5.0."
rpm -Uvh http://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
rpm -qa | grep -E "(zabbix-server-mysql|zabbix-web-mysql|zabbix-get)" || dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-get

#---Configuring DB
echo "###Configuring DB."
#create user for DB
mysql -uroot -palena <<EOF
CREATE DATABASE $DEFAULT_DATABASE DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;
GRANT ALL PRIVILEGES ON $USER_ZABBIX.* TO $DEFAULT_DATABASE@localhost IDENTIFIED BY '$PASSDW_ZABBIX';
EOF
#to apply the scheme, go to the directory, unpack the archive and restore the database
echo "###Unpack the archive and restore the database."
cd /usr/share/doc/zabbix-server-mysql
gunzip create.sql.gz
mysql -u root -p$MYSQL $DEFAULT_DATABASE < create.sql

#---Configuring zabbix_server.conf.
echo "###Configuring /etc/zabbix/zabbix_server.conf."
sed -i "s/# DBPassword=.*/DBPassword=$PASSDW_ZABBIX/" /etc/zabbix/zabbix_server.conf
sed -i "s/DBUser=.*/ DBUser=$USER_ZABBIX/" /etc/zabbix/zabbix_server.conf
sed -i "s/DBName=.*/ DBName=$DEFAULT_DATABASE/" /etc/zabbix/zabbix_server.conf
sed -i "s/Timeout=.*/Timeout=$TIMEOUT/" /etc/zabbix/zabbix_server.conf
#setting the owner for the /etc/zabbix/web directory
chown apache:apache /etc/zabbix/web

#---Run zabbix server
echo "###Run Zabbix server 5.0."
systemctl enable zabbix-server --now

#---Configuring /etc/nginx/nginx.conf and restart nginx.
echo "###Configuring nginx.conf."
sed -i 's+set $root_path /usr/share/nginx/html;+set $root_path /usr/share/zabbix;+' /etc/nginx/nginx.conf
sed -i '42s+root.*+root /usr/share/zabbix;+' /etc/nginx/nginx.conf
echo "###Restarting nginx service."
systemctl restart nginx
#check status zabbix-server
systemctl status zabbix-server
echo "###Done."
