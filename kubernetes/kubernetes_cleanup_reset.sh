#!/bin/bash

set -e

# Function to purge Kubernetes packages
purge_kubernetes_packages() {
    echo "Purging Kubernetes packages..."
    sudo apt-get purge -y --allow-change-held-packages \
        kubeadm kubelet kubectl kubernetes-cni containerd containerd.io
}

# Function to unhold and purge Kubernetes packages, remove dependencies
cleanup_kubernetes_packages() {
    echo "Cleaning up Kubernetes packages..."
    sudo apt-mark unhold kubelet kubeadm kubectl
    sudo apt-get purge -y kubelet kubeadm kubectl kubernetes-cni
    sudo apt-get autoremove -y
}

# Function to delete Kubernetes and Docker related directories
delete_kubernetes_directories() {
    echo "Deleting Kubernetes and Docker directories..."
    sudo rm -rf \
        /etc/docker \
        /etc/kubernetes \
        /var/lib/{kubelet,docker,etcd} \
        /etc/systemd/system/kubelet.service.d \
        /run/docker \
        ~/.kube
}

# Function to delete Kubernetes manifest files and CNI, containerd directories
delete_kubernetes_manifests_and_plugins() {
    echo "Deleting Kubernetes manifests and CNI, containerd directories..."
    sudo rm -rf /etc/kubernetes/manifests/{kube-apiserver.yaml,kube-controller-manager.yaml,kube-scheduler.yaml,etcd.yaml}
    sudo rm -rf /opt/cni /opt/containerd
}

# Function to reset Kubernetes cluster
reset_kubernetes_cluster() {
    echo "Resetting Kubernetes cluster..."
    sudo kubeadm reset -f
}

# Main script execution starts here
case "$1" in
    purge_packages)
        purge_kubernetes_packages
        delete_kubernetes_directories
        delete_kubernetes_manifests_and_plugins
        ;;
    cleanup_packages)
        cleanup_kubernetes_packages
        delete_kubernetes_directories
        delete_kubernetes_manifests_and_plugins
        ;;
    reset_cluster)
        reset_kubernetes_cluster
        ;;
    *)
        echo "Usage: $0 {purge_packages|cleanup_packages|reset_cluster}"
        exit 1;;
esac

echo "Kubernetes components and related files have been successfully cleaned up."



# curl -fsSL https://raw.githubusercontent.com/anti1346/codes/main/kubernetes/kubernetes_cleanup_reset.sh -o kubernetes_cleanup_reset.sh
# chmod +x kubernetes_cleanup_reset.sh
