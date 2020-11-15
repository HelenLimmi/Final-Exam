#!/bin/bash

###########################################################################
### Script for installing and configuring Zabbix client 5.0 on Centos 8 ###
###########################################################################

#---Configuration file
. ZabbixConfig

#---Install zabbix-agent
echo "###Installing Zabbix agent 5.0."
rpm -Uvh http://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
rpm -qa | grep zabbix-agent || dnf install -y zabbix-agent

#---Configuring file /etc/zabbix/zabbix_agentd.conf
echo "###Configuring file /etc/zabbix/zabbix_agentd.conf in accordance with the server IP address."
sed -i "s/Server=.*/Server=$SERVER_IP_ADDRESS/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=.*/ServerActive=$SERVER_IP_ADDRESS/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# Timeout=.*/Timeout=$TIMEOUT/" /etc/zabbix/zabbix_agentd.conf

#---Run zabbix-agent
echo "###Allow autorun Zabbix server and check status zabbix-agent."
systemctl enable zabbix-agent --now
systemctl restart zabbix-agent
#check status zabbix-agent
systemctl status zabbix-agent
echo "###Done."