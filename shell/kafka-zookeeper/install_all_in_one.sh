#!/bin/bash

JAVA_HOME="/opt/java"
ZOOKEEPER_HOME="/opt/zookeeper"
KAFKA_HOME="/opt/kafka"

setup_hosts() {
    # Comment out the line 127.0.1.1 in /etc/hosts
    sudo sed -i '/^127\.0\.1\.1/s/^/#/' /etc/hosts
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
    
    source ~/.bashrc
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
    sudo tee "${ZOOKEEPER_HOME}/conf/zoo.cfg" > /dev/null <<'EOF'
# 각 브로커에 고유한 ID 설정 (예: 0, 1, 2)
broker.id=0
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
zookeeper.connect=node1:2181,node2:2181,node3:2181
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
    
    # 각 노드에 고유한 ID 설정 (예: 1, 2, 3)
    echo "1" > "${ZOOKEEPER_HOME}/data/myid"

    # Configure ZooKeeper settings
    sudo tee "${ZOOKEEPER_HOME}/conf/zoo.cfg" > /dev/null <<'EOF'
tickTime=2000
initLimit=10
syncLimit=5

dataDir=${ZOOKEEPER_HOME}/data

clientPortAddress=0.0.0.0
clientPort=2181

maxClientCnxns=50
minSessionTimeout=2000
maxSessionTimeout=10000

server.1=node1:2888:3888
server.2=node2:2888:3888
server.3=node3:2888:3888
EOF
}

# Main
setup_hosts
install_oracle_java
install_kafka
install_zookeeper
