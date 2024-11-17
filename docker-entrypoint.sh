#!/bin/bash
set -e

# Initialize MySQL directories
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Initialize MySQL database
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # Initialize fresh MySQL data directory
    mysqld --initialize-insecure --user=mysql
    
    # Start MySQL server
    mysqld --user=mysql --daemonize

    # Wait for MySQL to be ready
    until mysqladmin ping >/dev/null 2>&1; do
        sleep 1
    done

    # Configure MySQL
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
        FLUSH PRIVILEGES;
EOSQL
fi

# Start MySQL in background
mysqld --user=mysql &

# Wait for MySQL to be ready
until mysqladmin ping >/dev/null 2>&1; do
    sleep 1
done

# Extract and install XUI
cd /root
tar -xf xui.tar.gz -C /home/xui/
chown -R xui:xui /home/xui

# Run XUI installation non-interactively 
echo "Y" | python3 /root/install.python3

# Apply crack
bash /root/install-crack.sh

# Keep container running and show logs
exec tail -f /var/log/mysql/error.log /var/log/xui/xui.log