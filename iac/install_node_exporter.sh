#!/bin/bash

Version=${Version:-1.8.1}
Arch=${Arch:-amd64}

if command -v apt &> /dev/null; then
    # Ubuntu
    OS=linux
elif command -v yum &> /dev/null; then
    # CentOS
    OS=linux
elif [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    OS=darwin
else
    echo "Unsupported operating system."
    exit 1
fi

# Create node_exporter user
if ! id -u node_exporter &>/dev/null; then
    useradd -r -m -s /usr/sbin/nologin node_exporter
fi

# Download and install node_exporter
cd /usr/local/src
wget -q https://github.com/prometheus/node_exporter/releases/download/v${Version}/node_exporter-${Version}.${OS}-${Arch}.tar.gz
tar xfz node_exporter-${Version}.${OS}-${Arch}.tar.gz
cp node_exporter-${Version}.${OS}-${Arch}/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service file
cat << 'EOF' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Reload systemd and enable service if port 9100 is not in use
if ! lsof -i:9100 &>/dev/null; then
    sudo systemctl --now enable node_exporter
    echo "Node Exporter is running. Access metrics at: curl http://localhost:9100/metrics"
else
    echo "Port 9100 is already in use. Node Exporter will not be started."
fi



### Shell Execute Command
# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/iac/install_node_exporter.sh | bash
# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/iac/install_node_exporter.sh | dos2unix | bash
