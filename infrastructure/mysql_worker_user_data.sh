#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

{
    sudo apt-get update -y
    sudo apt-get upgrade -y

    MYSQL_CLUSTER_URL="http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz"
    sudo mkdir -p /opt/mysqlcluster/home
    cd /opt/mysqlcluster/home
    sudo wget $MYSQL_CLUSTER_URL
    sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz
    sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

    # Source IP addresses
    source /tmp/ip_addresses.sh

    # Start MySQL Cluster Data Node
    sudo /opt/mysqlcluster/home/mysqlc/bin/ndbd -c ${MANAGER_DNS}:1186

} >> /var/log/progress.log 2>&1
