#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

{
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # Install MySQL Cluster and setup directories
    MYSQL_CLUSTER_URL="http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz"
    sudo mkdir -p /opt/mysqlcluster/home
    cd /opt/mysqlcluster/home
    sudo wget $MYSQL_CLUSTER_URL
    sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz
    sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

    # Setup MySQL Cluster config for manager
    source /tmp/ip_addresses.sh
    sudo mkdir -p /opt/mysqlcluster/deploy/conf
    CONFIG_FILE="/opt/mysqlcluster/deploy/conf/config.ini"

    echo "[ndb_mgmd]" > $CONFIG_FILE
    echo "hostname=${MANAGER_DNS}" >> $CONFIG_FILE
    echo "datadir=/opt/mysqlcluster/deploy/ndb_data" >> $CONFIG_FILE
    echo "nodeid=1" >> $CONFIG_FILE
    echo "" >> $CONFIG_FILE

    # Configure NDB nodes
    NODEID=2
    for WORKER_DNS in "${WORKER_DNS[@]}"
    do
        echo "[ndbd]" >> $CONFIG_FILE
        echo "hostname=${WORKER_DNS}" >> $CONFIG_FILE
        echo "nodeid=${NODEID}" >> $CONFIG_FILE
        echo "" >> $CONFIG_FILE
        ((NODEID++))
    done

    echo "[mysqld]" >> $CONFIG_FILE
    echo "nodeid=50" >> $CONFIG_FILE

    # Initialize MySQL Manager
    sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f $CONFIG_FILE --initial --configdir=/opt/mysqlcluster/deploy/conf/

    # Load and benchmark Sakila database
    SAKILA_DB_URL="https://downloads.mysql.com/docs/sakila-db.tar.gz"
    cd /tmp
    wget -q $SAKILA_DB_URL -O sakila-db.tar.gz
    tar -xzf sakila-db.tar.gz
    cd sakila-db
    sudo /opt/mysqlcluster/home/mysqlc/bin/mysql -u root < sakila-schema.sql
    sudo /opt/mysqlcluster/home/mysqlc/bin/mysql -u root < sakila-data.sql

    # Benchmark with sysbench
    sudo apt-get install -y sysbench
    sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-db=sakila --mysql-user=root --tables=10 --table-size=10000 prepare
    sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-db=sakila --mysql-user=root --threads=4 --time=60 run
    sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-db=sakila --mysql-user=root cleanup

} >> /var/log/progress.log 2>&1
