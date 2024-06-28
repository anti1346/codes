#!/bin/bash

VERSION=v0.49.1
ContainerDir="/docker-container/docker-cadvisor"

# Create directory if it doesn't exist
mkdir -p ${ContainerDir}

# Create docker-compose.yml file with variable substitution
cat << EOF > ${ContainerDir}/docker-compose.yml
version: '3.8'
services:

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:${VERSION}
    container_name: cadvisor
    restart: unless-stopped
    privileged: true
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
      - /dev/kmsg:/dev/kmsg
    ports:
      - 8080:8080
EOF

# Navigate to the directory and bring up the container
cd ${ContainerDir}
docker-compose up -d

echo "cAdvisor is running. Access it at http://localhost:8080"



### Shell Execute Command
# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/iac/install_node_exporter.sh | bash
# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/iac/install_node_exporter.sh | dos2unix | bash

