#!/bin/bash

set -e  # Exit script on error

JAVA_HOME="/opt/java"
KAFKA_HOME="/opt/kafka"
ZOOKEEPER_HOME="/opt/zookeeper"

IP1="192.168.0.111"
IP2="192.168.0.112"
IP3="192.168.0.113"

HOSTNAME1="node1"
HOSTNAME2="node2"
HOSTNAME3="node3"

# Get the current machine's IP
CURRENT_IP=$(hostname -I | awk '{print $1}')

# Check which IP matches and assign BROKER_ID and MYID accordingly
if [ "$CURRENT_IP" = "$IP1" ]; then
    BROKER_ID="0"
    MYID="1"
elif [ "$CURRENT_IP" = "$IP2" ]; then
    BROKER_ID="1"
    MYID="2"
elif [ "$CURRENT_IP" = "$IP3" ]; then
    BROKER_ID="2"
    MYID="3"
else
    echo "IP address does not match any known nodes. Exiting."
    exit 1
fi

# Function to check and add an entry in /etc/hosts if it doesn't exist
check_and_add_host() {
    local IP=$1
    local HOSTNAME=$2

    # Check if the IP and hostname are already in /etc/hosts
    if ! grep -q "$IP $HOSTNAME" /etc/hosts; then
        echo "$IP $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
        echo "Added $IP $HOSTNAME to /etc/hosts"
    else
        echo "$IP $HOSTNAME is already present in /etc/hosts"
    fi
}

setup_hosts() {
    # Comment out the line with 127.0.1.1 in /etc/hosts
    sudo sed -i '/^127\.0\.1\.1/s/^/#/' /etc/hosts

    # Add ZooKeeper cluster entries to /etc/hosts
    echo -e "\n# ZooKeeper Cluster" | sudo tee -a /etc/hosts > /dev/null

    # Call the check_and_add_host function for each node
    check_and_add_host "$IP1" "$HOSTNAME1"
    check_and_add_host "$IP2" "$HOSTNAME2"
    check_and_add_host "$IP3" "$HOSTNAME3"
}

install_oracle_java() {
    local JAVA_VERSION="17"
    local JAVA_DOWNLOAD_FILE="jdk-${JAVA_VERSION}_linux-x64_bin"
    
    cd /usr/local/src || exit 1
    wget https://download.oracle.com/java/${JAVA_VERSION}/latest/${JAVA_DOWNLOAD_FILE}.tar.gz || exit 1
    
    sudo mkdir -p "${JAVA_HOME}"
    sudo tar -xf "${JAVA_DOWNLOAD_FILE}.tar.gz" -C "${JAVA_HOME}" --strip-components=1
    
    # Add JAVA_HOME to environment variables
    if ! grep -q "JAVA_HOME" ~/.bashrc; then
        echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
    fi
    
    # Export for the current session
    export JAVA_HOME=${JAVA_HOME}
    export PATH=${JAVA_HOME}/bin:${PATH}
}

install_kafka() {
    local KAFKA_VERSION="3.8.0"
    local KAFKA_DOWNLOAD_FILE="kafka_2.13-${KAFKA_VERSION}"
    
    cd /usr/local/src || exit 1
    wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_DOWNLOAD_FILE}.tgz || exit 1
    
    sudo mkdir -p "${KAFKA_HOME}"
    sudo tar -xf "${KAFKA_DOWNLOAD_FILE}.tgz" -C "${KAFKA_HOME}" --strip-components=1
    
    sudo mkdir -p "${KAFKA_HOME}/logs"

    # Configure Kafka settings
    sudo tee "${KAFKA_HOME}/config/server.properties" > /dev/null <<EOF
# 각 브로커에 고유한 ID 설정 (예: 0, 1, 2)
broker.id=${BROKER_ID}
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=${KAFKA_HOME}/logs
# 파티션 수 설정
num.partitions=3 
num.recovery.threads.per.data.dir=1 
# 오프셋 토픽의 복제 계수 설정 (브로커 수만큼 설정)
offsets.topic.replication.factor=3
# 기본 복제 계수
default.replication.factor=3
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.retention.check.interval.ms=300000
# ZooKeeper 클러스터 정보
zookeeper.connect=${HOSTNAME1}:2181,${HOSTNAME2}:2181,${HOSTNAME3}:2181
zookeeper.connection.timeout.ms=18000
group.initial.rebalance.delay.ms=0
EOF
}

install_zookeeper() {
    local ZOOKEEPER_VERSION="3.8.4"
    local ZOOKEEPER_DOWNLOAD_FILE="apache-zookeeper-${ZOOKEEPER_VERSION}-bin"
    
    cd /usr/local/src || exit 1
    wget https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/${ZOOKEEPER_DOWNLOAD_FILE}.tar.gz || exit 1
    
    sudo mkdir -p "${ZOOKEEPER_HOME}"
    sudo tar -xf "${ZOOKEEPER_DOWNLOAD_FILE}.tar.gz" -C "${ZOOKEEPER_HOME}" --strip-components=1
    
    sudo mkdir -p "${ZOOKEEPER_HOME}/data"
    sudo chmod -R 755 "${ZOOKEEPER_HOME}/data"
    
    # Set unique ID for each node
    echo "${MYID}" | sudo tee "${ZOOKEEPER_HOME}/data/myid" > /dev/null

    # Configure ZooKeeper settings
    sudo tee "${ZOOKEEPER_HOME}/conf/zoo.cfg" > /dev/null <<EOF
tickTime=2000
initLimit=10
syncLimit=5

dataDir=${ZOOKEEPER_HOME}/data

clientPortAddress=0.0.0.0
clientPort=2181

maxClientCnxns=50
minSessionTimeout=2000
maxSessionTimeout=10000

server.1=${HOSTNAME1}:2888:3888
server.2=${HOSTNAME2}:2888:3888
server.3=${HOSTNAME3}:2888:3888
EOF

${ZOOKEEPER_HOME}/bin/zkServer.sh start

}

# Main
setup_hosts
install_oracle_java
install_kafka
install_zookeeper
