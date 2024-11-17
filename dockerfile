FROM ubuntu:20.04

# Add this to handle line endings first
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN apt-get update && apt-get install -y dos2unix && \
    dos2unix /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh && \
    mv /docker-entrypoint.sh /usr/local/bin/

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=agasta
ENV MYSQL_DATABASE=xui
ENV MYSQL_USER=xui_user
ENV MYSQL_PASSWORD=agasta
ENV AUTO_INSTALL=true

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget unzip python3 python3-pip sudo mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create xui user first
RUN useradd -r -s /bin/false xui && \
    groupadd -r xui || true && \
    usermod -a -G xui xui

# Download and set up XUI
WORKDIR /root
RUN wget https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip && \
    unzip XUI_1.5.12.zip && \
    wget https://github.com/amidevous/xui.one/releases/download/test/xui_crack.tar.gz && \
    mv xui_crack.tar.gz xui.tar.gz && \
    mkdir -p /home/xui && \
    tar -xf xui.tar.gz -C /home/xui/

# Copy installation scripts
COPY *.sh /root/
COPY install.python3 /root/
RUN chmod +x /root/*.sh

# Create directories and set permissions
RUN mkdir -p /home/xui/config /var/log/xui && \
    mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld /var/lib/mysql && \
    chown -R xui:xui /home/xui

EXPOSE 80 443 3306

VOLUME ["/home/xui", "/var/log/xui", "/var/lib/mysql"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]