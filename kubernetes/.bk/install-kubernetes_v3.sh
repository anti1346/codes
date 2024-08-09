#!/bin/bash

# Update and upgrade packages
sudo apt-get update

# Load necessary kernel modules
echo "overlay" | sudo tee /etc/modules-load.d/k8s.conf
echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl settings for Kubernetes networking
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install prerequisites
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# Add Docker repository and install containerd.io
sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y containerd.io

# Configure containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl --now enable containerd

# Add Kubernetes repository and install kubelet, kubeadm, kubectl
KUBERNETES_VERSION="1.27"
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# # Initialize Kubernetes cluster
# sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# # Set up kubeconfig for the current user
# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

# # Deploy Calico for networking (Master Node only)
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# # Monitor pod and node status
# kubectl get pods -n kube-system
# kubectl get nodes -o wide








###################################################################
#### containerd
# ls -l /opt/cni/bin
# sudo systemctl restart containerd
# cat /etc/containerd/config.toml | egrep SystemdCgroup
# sudo containerd config dump | egrep SystemdCgroup
# sudo systemctl status containerd --no-pager -l
# sudo journalctl -u containerd -f




###################################################################
#### kubelet
# sudo systemctl restart kubelet
# sudo systemctl status kubelet --no-pager -l
# sudo journalctl -u kubelet -f
# sudo journalctl -u kubelet -n 100 --no-pager
# sudo journalctl -xeu kubelet --no-pager -l


#sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

