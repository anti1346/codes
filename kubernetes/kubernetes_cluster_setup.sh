#!/bin/bash

configure_k8s_kernel_and_sysctl() {
    # Load necessary kernel modules
    modules_file="/etc/modules-load.d/k8s.conf"
    if ! lsmod | grep -q '^overlay'; then
        echo "overlay" | sudo tee -a $modules_file
        sudo modprobe overlay
    fi
    if ! lsmod | grep -q '^br_netfilter'; then
        echo "br_netfilter" | sudo tee -a $modules_file
        sudo modprobe br_netfilter
    fi

    # Configure sysctl settings for Kubernetes networking
    sysctl_file="/etc/sysctl.d/k8s.conf"
    if ! sysctl -a 2>/dev/null | grep -q "^net.bridge.bridge-nf-call-iptables"; then
        echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a $sysctl_file
    fi
    if ! sysctl -a 2>/dev/null | grep -q "^net.bridge.bridge-nf-call-ip6tables"; then
        echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a $sysctl_file
    fi
    if ! sysctl -a 2>/dev/null | grep -q "^net.ipv4.ip_forward"; then
        echo "net.ipv4.ip_forward = 1" | sudo tee -a $sysctl_file
    fi
    sudo sysctl --system
}

install_system_dependencies(){
    sudo apt-get update
    sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
}

setup_containerd(){
    sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y containerd.io

    sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

    CNI_VERSION="v1.5.1"
    CNI_TGZ="https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
    sudo mkdir -p /opt/cni/bin
    curl -fsSL "$CNI_TGZ" | sudo tar -C /opt/cni/bin -xz

    sudo systemctl --now enable containerd
}

setup_kubernetes_control_plane(){
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo mkdir -p -m 755 /etc/apt/keyrings
    KUBERNETES_VERSION="v1.27"
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}

setup_kubernetes_worker(){
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo mkdir -p -m 755 /etc/apt/keyrings
    KUBERNETES_VERSION="1.27"
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubectl
    sudo apt-mark hold kubelet kubectl
}

initialize_k8s_cluster(){
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 | tee $HOME/kubeadm_init_output.log

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

deploy_networking_with_calico(){
    # Deploy Calico for networking (Master Node only)
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

    echo "Waiting for Calico pods to be up and running..."
    kubectl wait --for=condition=Ready pods -l k8s-app=calico-node -n kube-system --timeout=300s

    # Monitor pod and node status
    echo "Calico deployment completed. Monitoring pod and node status:"
    kubectl get pods -n kube-system
    kubectl get nodes -o wide
}

# Main script execution starts here
case "$1" in
    system)
        configure_k8s_kernel_and_sysctl
        install_system_dependencies;;
    cri)
        setup_containerd;;
    init)
        initialize_k8s_cluster;;
    control_plane)
        setup_kubernetes_control_plane;;
    worker)
        setup_kubernetes_worker;;
    control_plane_nodes)
        configure_k8s_kernel_and_sysctl
        install_system_dependencies
        setup_containerd
        setup_kubernetes_control_plane;;
    worker_nodes)
        configure_k8s_kernel_and_sysctl
        install_system_dependencies
        setup_containerd
        setup_kubernetes_worker;;
    cni)
        deploy_networking_with_calico;;
    *)
        echo "Usage: $0 {system|cri|init|control_plane|worker|control_plane_nodes|worker_nodes|cni}"
        exit 1;;
esac



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubernetes_cluster_setup.sh -o kubernetes_cluster_setup.sh
# chmod +x kubernetes_cluster_setup.sh
